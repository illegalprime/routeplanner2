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

let poly;
let map;
let markerHook;
let routePath;
let startLoc;
let onMapLoad = [];
let polyHistory = [];
window.markers = [];

// This example creates a simple polygon representing the Bermuda Triangle.
window.initMap = function() {
    // init the map
    const mapEl = document.getElementById("map");
    map = new google.maps.Map(mapEl, {
        zoom: 11,
        center: { lat: 42.33735813662984, lng: -71.18956410933751 },
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
    if (mapEl.dataset.loadMarkers) {
        refresh_markers(document.getElementById(mapEl.dataset.loadMarkers));
    }
    else {
        // create a marker from the canvass location
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
    }
    // map load call backs
    for (const f of onMapLoad) {
        f(map);
    }
    onMapLoad = true;
};

let debounce_memo = "";
function refresh_selection() {
    if (!google.maps.geometry || !markerHook) {
        return;
    }
    const containsLocation = google.maps.geometry.poly.containsLocation;
    const inside = markers.filter(marker => {
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

function refresh_markers(table) {
    // remove old markers
    for (const marker of markers) {
        marker.setMap(null);
    }
    markers = [];
    // remove old route
    if (routePath) routePath.setMap(null);
    routePath = undefined;

    // loop through new data set
    const cases = Array(...table.getElementsByTagName('tr'));
    const max_days = parseInt(table.dataset.daysFilter);
    const now = Date.now();
    cases.forEach((court_case, idx) => {
        // ignore table headers
        if (court_case.dataset.ignore) return;
        // color marker based on how old it is
        const date = Date.parse(court_case.dataset.date);
        const diff = (now - date) / (1000 * 3600 * 24);
        const intensity = parseInt(255 * (1 - (diff / max_days))).toString(16);
        const color = `#${intensity}0000`;

        let markerSize = 3;
        let label = undefined;

        if (table.dataset.zoom) {
            markerSize = 8;
            label = {
                color: "#ffffff",
                fontWeight: "bold",
                fontSize: "15px",
                text: idx.toString(),
            };
        }

        // make the new marker
        const marker = new google.maps.Marker({
            position: {
                lat: parseFloat(court_case.dataset.lat),
                lng: parseFloat(court_case.dataset.lng),
            },
            label,
            icon: {
                path: google.maps.SymbolPath.CIRCLE,
                fillColor: color,
                fillOpacity: 1,
                strokeColor: color,
                scale: markerSize,
            },
            map,
            title: [
                `Landlord: ${court_case.dataset.landlord}`,
                `Date: ${court_case.dataset.date}`,
                `Address: ${court_case.dataset.street}, ${court_case.dataset.city}`,
            ].join('\n')
        });
        marker.case_id = court_case.dataset.caseId;
        markers.push(marker);
    });

    if (table.dataset.connect === "true") {
        routePath = new google.maps.Polyline({
            path: markers.map(m => m.position),
            geodesic: true,
            strokeColor: "#FF0000",
            strokeOpacity: 1.0,
            strokeWeight: 2,
        });
        routePath.setMap(map);
    }

    if (table.dataset.zoom) {
        const bounds = new google.maps.LatLngBounds();
        markers.forEach(m => bounds.extend(m.getPosition()));
        map.fitBounds(bounds);
    }
}

const Hooks = {
    MapDisplay: {
        mounted() {
            markerHook = this;
            const table = this.el;
            if (onMapLoad !== true) {
                onMapLoad.push(() => refresh_markers(table));
            }
            else {
                refresh_markers(table);
            }
        },
        updated() {
            refresh_markers(this.el);
        },
    },
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
