// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket


var menu_buttons = document.getElementsByClassName("menu-item");

var menuClick = function(e) {
	var pressedID = e.originalTarget.getAttribute("data-menu-controlled");
    var menu_items = document.getElementsByClassName("menu-controlled");
	Array.from(menu_items).forEach(function(menu_item) {
        menu_item.classList.add("hidden");
    });
    var pressed = document.getElementById(pressedID);
    pressed.classList.remove("hidden");

};

Array.from(menu_buttons).forEach(function(menu_button) {
      menu_button.addEventListener('click', menuClick);
    });
