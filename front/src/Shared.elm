module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Navigation exposing (Key)
import DesignSystem.Spacing as Spacing exposing (marginTop)
import DesignSystem.Stylesheet exposing (stylesheet)
import DesignSystem.Typography exposing (FontFamily(..), TypographyType(..), typography)
import Html.Styled exposing (a, div, footer, h1, header, p, span)
import Html.Styled.Attributes exposing (class, css, href)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Task
import Time
import Url exposing (Url)
import Utils.Time as Time exposing (TimeAndZone, defaultTimeAndZone)



-- INIT


type alias Flags =
    ()


type alias Model =
    { url : Url
    , key : Key
    , timeAndZone : TimeAndZone
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model url key defaultTimeAndZone
    , Task.map2 Time.fromTimeAndZone Time.now Time.here
        |> Task.perform InitialTimeAndZoneFetched
    )



-- UPDATE


type Msg
    = InitialTimeAndZoneFetched TimeAndZone
    | UpdateTime Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialTimeAndZoneFetched timeAndZone ->
            ( { model | timeAndZone = timeAndZone }, Cmd.none )

        UpdateTime time ->
            ( { model | timeAndZone = Time.updateTime model.timeAndZone time }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (10 * 1000) UpdateTime



-- VIEW


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
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
