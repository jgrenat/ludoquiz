module Model.Quiz exposing (Answer, Question, Quiz, QuizId, QuizPreview, findAll, findBySlug)

import Http exposing (expectJson)
import Id exposing (Id(..))
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import List.Nonempty as Nonempty exposing (Nonempty)
import RemoteData exposing (WebData)
import Time exposing (Posix(..))


type QuizIdMarker
    = QuizIdMarker Never


type alias QuizId =
    Id String QuizIdMarker


type AnswerIdMarker
    = AnswerIdMarker Never


type alias AnswerId =
    Id String AnswerIdMarker


type alias Quiz =
    { id : QuizId
    , publicationDate : Posix
    , slug : String
    , image : String
    , title : String
    , description : Encode.Value
    , questions : Nonempty Question
    }


type alias QuizPreview =
    { id : QuizId
    , publicationDate : Posix
    , slug : String
    , image : String
    , title : String
    , description : Encode.Value
    , questionsCount : Int
    }


type alias Question =
    { question : String, image : Maybe String, answers : Nonempty Answer }


type alias Answer =
    { id : AnswerId, answer : String, isCorrect : Bool }


findAll : (WebData (List QuizPreview) -> msg) -> Cmd msg
findAll toMsg =
    Http.get
        { url = "https://y3uf7k80.apicdn.sanity.io/v1/data/query/production?query=*%5B_type%20%3D%3D%20'quiz'%20%26%26%20publicationDate%20!%3D%20null%20%26%26%20dateTime(publicationDate)%20%3C%3D%20dateTime(now())%5D%0A%7C%20order(publicationDate%20desc)%0A%7B_id%2C%20publicationDate%2C%20slug%2C%20title%2C%20description%2C%20%22image%22%3A%20image.asset-%3Eurl%2C%20%22questionsCount%22%3A%20count(questions)%7D"
        , expect = expectJson (RemoteData.fromResult >> toMsg) (sanityDecoder previewDecoder)
        }


findBySlug : (WebData Quiz -> msg) -> String -> Cmd msg
findBySlug toMsg slug =
    Http.get
        { url = "https://y3uf7k80.apicdn.sanity.io/v1/data/query/production?query=*%5B_type%20%3D%3D%20'quiz'%20%26%26%20slug.current%20%3D%3D'" ++ slug ++ "'%5D%7B_id%2C%20publicationDate%2C%20slug%2C%20title%2C%20description%2C%20%22image%22%3A%20image.asset-%3Eurl%2C%20questions%5B%5D%20%7B%20question%2C%20%22image%22%3A%20image.asset-%3Eurl%2C%20answers%7D%7D"
        , expect = expectJson (RemoteData.fromResult >> toMsg) (sanitySingleElementDecoder decoder)
        }


decoder : Decoder Quiz
decoder =
    Decode.map7 Quiz
        (Decode.field "_id" (Id.decoder Decode.string))
        (Decode.field "publicationDate" Iso8601.decoder)
        (Decode.at [ "slug", "current" ] Decode.string)
        (Decode.field "image" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.value)
        (Decode.field "questions" (nonemptyLisDecoder questionDecoder))


nonemptyLisDecoder : Decoder a -> Decoder (Nonempty a)
nonemptyLisDecoder decoder_ =
    Decode.oneOrMore (\head tail -> Nonempty.fromElement head |> Nonempty.replaceTail tail) decoder_


previewDecoder : Decoder QuizPreview
previewDecoder =
    Decode.map7 QuizPreview
        (Decode.field "_id" (Id.decoder Decode.string))
        (Decode.field "publicationDate" Iso8601.decoder)
        (Decode.at [ "slug", "current" ] Decode.string)
        (Decode.field "image" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.value)
        (Decode.field "questionsCount" Decode.int)


sanitySingleElementDecoder : Decoder a -> Decoder a
sanitySingleElementDecoder decoder_ =
    sanityDecoder decoder_
        |> Decode.andThen
            (\list ->
                case list of
                    first :: _ ->
                        Decode.succeed first

                    [] ->
                        Decode.fail "No element found in the results list"
            )


sanityDecoder : Decoder a -> Decoder (List a)
sanityDecoder decoder_ =
    Decode.field "result" (Decode.list decoder_)


questionDecoder : Decoder Question
questionDecoder =
    Decode.map3 Question
        (Decode.field "question" Decode.string)
        (Decode.maybe (Decode.field "image" Decode.string))
        (Decode.field "answers" (nonemptyLisDecoder answerDecoder))


answerDecoder : Decoder Answer
answerDecoder =
    Decode.map3 Answer
        (Decode.field "_key" (Id.decoder Decode.string))
        (Decode.field "answer" Decode.string)
        (Decode.oneOf [ Decode.field "isCorrect" Decode.bool, Decode.succeed False ])
