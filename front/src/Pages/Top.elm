module Pages.Top exposing (Model, Msg, Params, page)

import Css exposing (backgroundColor, center, color, displayFlex, flexWrap, justifyContent, none, pct, spaceBetween, textAlign, textDecoration, width, wrap)
import Css.Global as Css exposing (Snippet)
import DesignSystem.Colors as Colors
import DesignSystem.Spacing as Spacing exposing (marginTop)
import DesignSystem.Typography exposing (TypographyType(..), typography)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, href, property)
import Model.Quiz as Quiz exposing (QuizPreview)
import RemoteData exposing (RemoteData(..), WebData)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route(..))
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.Time as Time exposing (TimeAndZone)


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , save = \_ sharedModel -> sharedModel
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    { quizPreviews : WebData (List QuizPreview)
    , timeAndZone : TimeAndZone
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init { timeAndZone } { params } =
    ( { quizPreviews = Loading, timeAndZone = timeAndZone }, Quiz.findAll QuizFetched )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { model | timeAndZone = shared.timeAndZone }
    , Cmd.none
    )



-- UPDATE


type Msg
    = QuizFetched (WebData (List QuizPreview))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        QuizFetched quizPreviewsData ->
            ( { model | quizPreviews = quizPreviewsData }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "LudoQuiz"
    , body =
        [ Css.global styles
        , div []
            [ typography HeroText p [ class "catchPhrase" ] "Chaque jour un nouveau quiz sur les jeux de société !"
            , case model.quizPreviews of
                Success quizPreviews ->
                    List.map (viewQuizPreview model.timeAndZone) quizPreviews |> ul [ class "quizPreviews" ]

                Failure _ ->
                    typography Paragraph p [] "Une erreur s'est produite en chargeant les ludoquiz :-/"

                Loading ->
                    typography Paragraph p [] "Chargement des ludoquiz..."

                NotAsked ->
                    text ""
            ]
        ]
    }


viewQuizPreview : TimeAndZone -> QuizPreview -> Html Msg
viewQuizPreview timeAndZone quizPreview =
    let
        route =
            Quiz__QuizSlug_String { quizSlug = quizPreview.slug }
                |> Route.toString
    in
    li [ class "quizDetails" ]
        [ a [ href route ]
            [ div [ class "panel quizDetailsElements" ]
                [ typography Title2 h3 [ class "quizTitle" ] quizPreview.title
                , typography DateTime p [ class "quizTime" ] (Time.humanReadableDate timeAndZone quizPreview.publicationDate)
                , node "block-content" [ class "description", property "blocks" quizPreview.description ] []
                ]
            ]
        ]



-- STYLES


styles : List Snippet
styles =
    [ Css.class "catchPhrase"
        [ textAlign center ]
    , Css.class "quizDetails"
        [ marginTop Spacing.M
        , Css.children [ Css.a [ textDecoration none ] ]
        ]
    , Css.class "quizDetailsElements"
        [ displayFlex
        , flexWrap wrap
        , justifyContent spaceBetween
        ]
    , Css.class "quizTitle"
        [ color Colors.secondary
        ]
    , Css.class "quizTime"
        [ color Colors.secondary
        ]
    , Css.class "description"
        [ width (pct 100)
        , marginTop Spacing.S
        ]
    ]
