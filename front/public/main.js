// Initial data passed to Elm (should match `Flags` defined in `Shared.elm`)
// https://guide.elm-lang.org/interop/flags.html
const flags = null;

// Start our Elm application
const app = Elm.Main.init({ flags: flags });

// Ports go here
// https://guide.elm-lang.org/interop/ports.html



app.ports.logEvent.subscribe(eventName => plausible(eventName));


// const openDbRequest = indexedDB.open('ludoquiz', 1);
//
//
// openDbRequest.onupgradeneeded = function() {
//   const db = openDbRequest.result;
//   if (!db.objectStoreNames.contains('results')) {
//     db.createObjectStore('results', {keyPath: 'id'});
//   }
// };
// openDbRequest.onsuccess = function() {
//   // triggers if the client had no database
//   // ...perform initialization...
// };
