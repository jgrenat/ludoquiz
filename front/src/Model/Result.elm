module Model.Result exposing (Result, decoder, encode)

import Id
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Model.Quiz exposing (QuizId)


type alias Result =
    { id : QuizId
    , score : Int
    }


decoder : Decoder Result
decoder =
    Decode.map2 Result
        (Decode.field "id" (Id.decoder Decode.string))
        (Decode.field "score" Decode.int)


encode : Result -> Encode.Value
encode result =
    Encode.object
        [ ( "id", Id.encode Encode.string result.id )
        , ( "score", Encode.int result.score )
        ]
