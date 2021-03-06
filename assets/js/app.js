// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";

import {Socket} from "phoenix";
import LiveSocket from "phoenix_live_view";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

const startSvg = "M12 .587l3.668 7.568 8.332 1.151-6.064 5.828 1.48 8.279-7.416-3.967-7.417 3.967 1.481-8.279-6.064-5.828 8.332-1.151z";

let markerHook;
let startLoc;
window.markers = {};

// This example creates a simple polygon representing the Bermuda Triangle.
let poly;
let polyHistory = [];
window.initMap = function() {
    // init the map
    const mapEl = document.getElementById("map");
    window.map = new google.maps.Map(mapEl, {
        zoom: 12,
        center: {
            lat: 42.32187556128396,
            lng: -71.10476338912267,
        },
        clickableIcons: false,
    });
    if (mapEl.dataset.editable !== "no") {
        // Add a listener for the click event
        map.addListener("click", addLatLng);
        const clearPoly = () => {
            poly.setMap(null);
            poly = undefined;
            polyHistory = [];
            refresh_selection();
        };
        const undoPoly = () => {
            if (!poly || !polyHistory.length) return;
            const idxUndo = polyHistory.pop();
            if (polyHistory.length) {
                // undo one point
                poly.getPath().removeAt(idxUndo);
                refresh_selection();
            }
            else {
                // if this is the last vertex just clear it
                clearPoly();
            }
        };
        document.getElementById("clear-polygon-btn").addEventListener("click", clearPoly);
        document.getElementById("undo-polygon-btn").addEventListener("click", undoPoly);
    }
    // create a marker from the canvass location
    // TODO: implement changing this and planning around it
    startLoc = new google.maps.Marker({
        position: {
            lat: 42.2986649,
            lng: -71.1169668,
        },
        icon: {
            path: startSvg,
            fillColor: "purple",
            fillOpacity: 0.8,
            strokeWeight: 0,
            rotation: 0,
            scale: 1,
        },
        map: map,
    });
    // send message we're ready for map data
    if (markerHook) markerHook.pushEvent("map_init", {});
    // if there's an event run it
    if (window.onMapLoad) {
        window.onMapLoad();
    }
};

function addLatLng(event) {
    const vertex = event.latLng;
    if (poly) {
        // find the closest point to the vertex about to be added
        const distances = poly.getPath().getArray().map(point => {
            return Math.hypot(point.lat() - vertex.lat(), point.lng() - vertex.lng());
        });
        const smallest = distances.reduce((lowest, next, idx) => {
            return next < distances[lowest] ? idx : lowest;
        }, 0);
        // see if it should be added to the left or right of it
        const left = smallest === 0 ? distances.length - 1 : smallest - 1;
        const right = smallest === distances.length - 1 ? 0 : smallest + 1;
        const insert = distances[right] < distances[left] ? right : smallest;
        // insert into the path
        poly.getPath().insertAt(insert, vertex);
    }
    else {
        // Construct the polygon.
	      poly = new google.maps.Polygon({
	          paths: [vertex],
    	      strokeColor: "#FF0000",
    	      strokeOpacity: 0.8,
    	      strokeWeight: 2,
    	      fillColor: "#FF0000",
    	      fillOpacity: 0.35,
    	      editable: true,
            draggable: true,
  	    });
        polyHistory.push(0);
        google.maps.event.addListener(poly, 'drag', () => {
            refresh_selection();
        });
        google.maps.event.addListener(poly.getPath(), 'insert_at', idx => {
            polyHistory.push(idx);
            refresh_selection();
        });
        google.maps.event.addListener(poly.getPath(), 'set_at', () => {
            refresh_selection();
        });
  	    poly.setMap(map);
    }
}

let debounce_memo = "";
function refresh_selection() {
    if (!google.maps.geometry || !markerHook) {
        return;
    }
    const containsLocation = google.maps.geometry.poly.containsLocation;
    const inside = Object.values(markers).filter(marker => {
        return !hidden.has(marker.case_id);
    }).filter(marker => {
        return poly && containsLocation(marker.getPosition(), poly);
    }).map(marker => {
        return marker.case_id;
    });
    const memo = inside.join();
    if (memo == debounce_memo) {
        return;
    }
    debounce_memo = memo;
    markerHook.pushEvent("selected_cases", { cases: inside });
}

function marker_icon(file_date, opts) {
    // color marker based on how old it is
    const now = Date.now();
    const date = Date.parse(file_date);
    const diff = (now - date) / (1000 * 3600 * 24);
    const intensity = parseInt(255 * (1 - (diff / opts.days))).toString(16);
    const color = `#${intensity}0000`;
    return {
        path: google.maps.SymbolPath.CIRCLE,
        fillColor: color,
        fillOpacity: 1,
        strokeColor: color,
        scale: opts.enumerate ? 8 : 3,
    };
}

function marker_label(opts, idx) {
    if (!opts.enumerate) return undefined;
    return {
        color: "#ffffff",
        fontWeight: "bold",
        fontSize: "15px",
        text: (idx + 1).toString(),
    };
}

function add_marker(court_case, opts, idx) {
    // make the new marker
    const icon = marker_icon(court_case.file_date, opts);
    const label = marker_label(opts, idx);
    const marker = new google.maps.Marker({
        position: {
            lat: parseFloat(court_case.latitude),
            lng: parseFloat(court_case.longitude),
        },
        label,
        icon,
        title: [
            `Landlord: ${court_case.plaintiff}`,
            `Date: ${court_case.file_date}`,
            `Address: ${court_case.street}, ${court_case.city}`,
        ].join('\n')
    });
    marker.case_id = court_case.case_id;
    marker.file_date = court_case.file_date;
    return marker;
}

let map_opts = {};
let hidden = new Set();
function refresh_markers(scatter) {
    // get new opts if available
    let refresh_colors = false;
    if (scatter.zoom !== undefined) map_opts.zoom = scatter.zoom;
    if (scatter.days !== undefined) {
        if (map_opts.days !== undefined) refresh_colors = true;
        map_opts.days = scatter.days;
    }

    // find point diff
    const points = scatter.points;
    const scatter_set = new Set(points.map(c => c.case_id));
    const to_add = points.filter(c => !markers[c.case_id]);
    const to_del = Object.keys(markers).filter(c => !scatter_set.has(c));

    // create all markers first
    for (const point of to_add) {
        markers[point.case_id] = add_marker(point, map_opts);
    }
    // if the days filter changed, reset colors on everything
    if (refresh_colors) {
        for (const marker of Object.values(markers)) {
            marker.setIcon(marker_icon(marker.file_date, map_opts));
        }
    }

    // now show them and delete old ones quickly
    const not_hidden = to_add.filter(c => !hidden.has(c.case_id));
    for (const point of not_hidden) {
        markers[point.case_id].setMap(map);
    }
    for (const case_id of to_del) {
        markers[case_id].setMap(null);
        delete markers[case_id];
    }
}

function hidden_markers(hide_req) {
    const now_hidden = new Set(hide_req.ids);
    const to_hide = hide_req.ids.filter(id => !hidden.has(id));
    const to_show = [...hidden].filter(id => !now_hidden.has(id));
    hidden = now_hidden;

    for (const id of to_hide) {
        if (markers[id]) markers[id].setMap(null);
    }
    for (const id of to_show) {
        if (markers[id]) markers[id].setMap(map);
    }
}

let currentRoute = [];
let routePath = undefined;
function refresh_route(route) {
    const opts = { enumerate: true, ...map_opts };
    currentRoute.forEach(r => r.setMap(null));
    currentRoute = route.points.map((p, i) => add_marker(p, opts, i));
    currentRoute.forEach(m => m.setMap(map));

    if (routePath) routePath.setMap(null);
    routePath = new google.maps.Polyline({
        path: currentRoute.concat(currentRoute[0] || []).map(m => m.position),
        geodesic: true,
        strokeColor: "#FF0000",
        strokeOpacity: 1.0,
        strokeWeight: 2,
    });
    routePath.setMap(map);

    // zoom to just show the markers if needed
    if (route.zoom) {
        const bounds = new google.maps.LatLngBounds();
        currentRoute.forEach(m => bounds.extend(m.getPosition()));
        map.fitBounds(bounds);
    }
}
window.refresh_route = refresh_route;

const Hooks = {
    OnLoad: {
        mounted() {
            this.handleEvent('map-scatter', refresh_markers);
            this.handleEvent('map-route', refresh_route);
            this.handleEvent('map-hide', hidden_markers);
            if (map) this.pushEvent("map_init", {});
            markerHook = this;
        }
    }
};

let liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    hooks: Hooks,
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is enabled for the duration of the browser session.
// Call disableLatencySim() to disable:
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
