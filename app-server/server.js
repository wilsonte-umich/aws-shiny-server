/*  ------------------------------------------------------------------------
    enable cookies for storing user and session history information
    ------------------------------------------------------------------------*/
function getCookie(cname) {
  let name = cname + "=";
  let decodedCookie = decodeURIComponent(document.cookie);
  let ca = decodedCookie.split(';');
  for(var i = 0; i <ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) === 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}
function setCookie(cname, data, nDays) {
    let currentValue = getCookie(cname);
    if (currentValue === "" || data.force) currentValue = data.value;
    let secure = ";secure"; // secure means transmit over https only
    if (nDays === undefined) { // a session cookie; note: cannot set HttpOnly in javascript
        document.cookie = cname + "=" + currentValue + ";path=/;samesite=lax" + secure;
    } else { // a permanent cookie
        var d = new Date();
        d.setTime(d.getTime() + (nDays * 24 * 60 * 60 * 1000));
        var expires = "expires="+ d.toUTCString();
        document.cookie = cname + "=" + currentValue + ";path=/;samesite=lax" + secure + ";" + expires;
    }
}
// user and session keys (use maximum possible security)
Shiny.addCustomMessageHandler('initializeSession', function(data) { 
    let priorCookie = decodeURIComponent(document.cookie);
    let cookie = decodeURIComponent(document.cookie);
    let sessionNonceElement = document.getElementById('sessionNonce');
    let sessionNonce = sessionNonceElement.value;
    sessionNonceElement.remove(); // sessionNonce is a one-time sessionKey lookup passed from ui.R to server.R
    Shiny.setInputValue(
        'initializeSession',
        {priorCookie: priorCookie, cookie: cookie, sessionNonce: sessionNonce},
        {priority: "event"}
    );
});

// any generic cookie, e.g., app usage history (low security level here)
Shiny.addCustomMessageHandler('setDocumentCookie', function(cookie) { // Shiny to javascript
    cookie.data.force = true;    
    setCookie(cookie.name, cookie.data, cookie.nDays);
});
Shiny.addCustomMessageHandler('setCookieInput', function(cookieName) { // javascript to Shiny
    var decodedCookie = decodeURIComponent(document.cookie);
    Shiny.setInputValue(cookieName, decodedCookie, {priority: "event"});
});
