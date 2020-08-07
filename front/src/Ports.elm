port module Ports exposing (logEvent, resultsFetched, storeResult)

import Json.Encode as Encode


port logEvent : String -> Cmd msg


port storeResult : Encode.Value -> Cmd msg


port resultsFetched : (Encode.Value -> msg) -> Sub msg
