module Shared exposing
    ( Flags
    , Model
    , Msg
    , ScreenSize
    , getResultForQuiz
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Events
import Browser.Navigation exposing (Key)
import DesignSystem.Spacing as Spacing exposing (marginTop)
import DesignSystem.Stylesheet exposing (stylesheet)
import DesignSystem.Typography exposing (FontFamily(..), TypographyType(..), typography)
import Dict exposing (Dict)
import Html.Styled exposing (a, div, footer, h1, header, p, span)
import Html.Styled.Attributes exposing (class, css, href)
import Id
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Model.Quiz exposing (QuizId)
import Model.Result as Result
import Ports
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Task
import Time
import Url exposing (Url)
import Utils.Time as Time exposing (TimeAndZone, defaultTimeAndZone)



-- INIT


type alias Flags =
    Encode.Value


type alias ScreenSize =
    { width : Float
    , height : Float
    }


type alias Model =
    { url : Url
    , key : Key
    , timeAndZone : TimeAndZone
    , results : Dict String Int
    , screenSize : Maybe ScreenSize
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        screenSize =
            Decode.decodeValue flagsDecoder flags
                |> Result.toMaybe
    in
    ( Model url key defaultTimeAndZone Dict.empty screenSize
    , Task.map2 Time.fromTimeAndZone Time.now Time.here
        |> Task.perform InitialTimeAndZoneFetched
    )


flagsDecoder : Decoder ScreenSize
flagsDecoder =
    Decode.map2 ScreenSize
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)



-- UPDATE


type Msg
    = InitialTimeAndZoneFetched TimeAndZone
    | UpdateTime Time.Posix
    | ResultsFetched Encode.Value
    | ScreenSizeChanged ScreenSize


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialTimeAndZoneFetched timeAndZone ->
            ( { model | timeAndZone = timeAndZone }, Cmd.none )

        UpdateTime time ->
            ( { model | timeAndZone = Time.updateTime model.timeAndZone time }, Cmd.none )

        ResultsFetched value ->
            let
                resultsDict : Dict String Int
                resultsDict =
                    case Decode.decodeValue (Decode.list Result.decoder) value of
                        Ok results ->
                            List.map (\result -> ( Id.to result.id, result.score )) results
                                |> Dict.fromList

                        _ ->
                            Dict.empty
            in
            ( { model | results = resultsDict }, Cmd.none )

        ScreenSizeChanged screenSize ->
            ( { model | screenSize = Just screenSize }, Cmd.none )


getResultForQuiz : Model -> QuizId -> Maybe Int
getResultForQuiz model id =
    Dict.get (Id.to id) model.results


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every (10 * 1000) UpdateTime
        , Ports.resultsFetched ResultsFetched
        , Browser.Events.onResize
            (\width height ->
                ScreenSize (toFloat width) (toFloat height)
                    |> ScreenSizeChanged
            )
        ]



-- VIEW


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } _ =
    { title = page.title
    , body =
        [ stylesheet
        , div [ class "container" ]
            [ header []
                [ a [ href (Route.toString Route.Top) ]
                    [ h1 []
                        [ typography MainTitleFirstPart span [] "Ludo"
                        , typography MainTitleSecondPart span [] "Quiz"
                        ]
                    ]
                ]
            , div [ css [ marginTop Spacing.M ] ] page.body
            , footer [ class "footer" ]
                [ p []
                    [ typography FooterText span [] "Envie de contribuer ? "
                    , typography FooterText a [ href "mailto:contact@ludoquiz.eu" ] "Envoyez-nous vos Ludoquiz et ils seront publiés !"
                    ]
                ]
            ]
        ]
    }
