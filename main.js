// Initial data passed to Elm (should match `Flags` defined in `Shared.elm`)
// https://guide.elm-lang.org/interop/flags.html
const flags = { width: window.innerWidth, height: window.innerHeight };

// Start our Elm application
const app = Elm.Main.init({ flags: flags });

let storeResult = () => {};

app.ports.logEvent.subscribe(eventName => plausible(eventName));
app.ports.storeResult.subscribe(quizResult => storeResult(quizResult));

if (window.indexedDB) {
  const openDbRequest = indexedDB.open("ludoquiz", 1);

  openDbRequest.onupgradeneeded = function() {
    const db = openDbRequest.result;
    if (!db.objectStoreNames.contains("results")) {
      db.createObjectStore("results", { keyPath: "id" });
    }
  };

  openDbRequest.onsuccess = function() {
    const db = openDbRequest.result;
    storeResult = getStoreResultFunction(db);
    retrieveAllResults(db);
  };
}

function getStoreResultFunction(db) {
  return quizResult => {
    const resultsObjectStore = db
      .transaction(["results"], "readwrite")
      .objectStore("results");
    const getResultRequest = resultsObjectStore.get(quizResult.id);
    getResultRequest.onsuccess = () => {
      if (getResultRequest.result) {
        resultsObjectStore.put({
          id: quizResult.id,
          score: Math.max(quizResult.score, getResultRequest.result.score)
        });
      } else {
        resultsObjectStore.add(quizResult);
      }
    };
    getResultRequest.onerror = () => {
      resultsObjectStore.add(quizResult);
    };
  };
}

function retrieveAllResults(db) {
  const resultsObjectStore = db
    .transaction(["results"], "readwrite")
    .objectStore("results");
  const results = [];
  resultsObjectStore.openCursor().onsuccess = function(event) {
    const cursor = event.target.result;
    if (cursor) {
      results.push(cursor.value);
      cursor.continue();
    } else {
      app.ports.resultsFetched.send(results);
    }
  };
}
