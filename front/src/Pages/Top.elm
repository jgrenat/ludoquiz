module Pages.Top exposing (Model, Msg, Params, page)

import Css exposing (borderRadius, center, color, display, displayFlex, flexWrap, hidden, inline, justifyContent, maxWidth, none, overflow, pct, px, spaceBetween, textAlign, textDecoration, width, wrap)
import Css.Global as Css exposing (Snippet)
import DesignSystem.Colors as Colors
import DesignSystem.Responsive exposing (onSmallScreen)
import DesignSystem.Spacing as Spacing exposing (marginTop)
import DesignSystem.Typography exposing (TypographyType(..), typography)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (alt, class, href, property, src, target)
import Html.Styled.Events exposing (onClick)
import List.Extra as List
import Model.Quiz as Quiz exposing (QuizPreview)
import Ports
import RemoteData exposing (RemoteData(..), WebData)
import Shared exposing (getResultForQuiz)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route(..))
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.Html exposing (viewMaybe)
import Utils.Time as Time exposing (TimeAndZone)


philibertLink : String
philibertLink =
    "https://www.philibertnet.com/fr/#ae356-12"


philibertBannerUrl : String
philibertBannerUrl =
    "/images/banner-philibert-desktop.jpg"


philibertMobileBannerUrl : String
philibertMobileBannerUrl =
    "/images/banner-philibert-mobile.jpg"


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
    , sharedModel : Shared.Model
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init sharedModel { params } =
    ( { quizPreviews = Loading, sharedModel = sharedModel }, Quiz.findAll QuizFetched )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load sharedModel model =
    ( { model | sharedModel = sharedModel }
    , Cmd.none
    )



-- UPDATE


type Msg
    = QuizFetched (WebData (List QuizPreview))
    | PhilibertBannerClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        QuizFetched quizPreviewsData ->
            ( { model | quizPreviews = quizPreviewsData }, Cmd.none )

        PhilibertBannerClicked ->
            ( model, Ports.logEvent "PhilibertBannerClicked" )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


type QuizListElement
    = QuizElement QuizPreview
    | BannerElement


view : Model -> Document Msg
view model =
    { title = "LudoQuiz"
    , body =
        [ Css.global styles
        , div []
            [ typography HeroText p [ class "catchPhrase" ] "Chaque jour un nouveau quiz sur les jeux de société !"
            , case model.quizPreviews of
                Success quizPreviews ->
                    let
                        quizListWithBanners =
                            List.map QuizElement quizPreviews
                                |> List.greedyGroupsOf 5
                                |> List.intercalate [ BannerElement ]
                    in
                    List.map
                        (\element ->
                            case element of
                                QuizElement quizPreview ->
                                    viewQuizPreview model.sharedModel quizPreview

                                BannerElement ->
                                    viewBanner
                        )
                        quizListWithBanners
                        |> ul [ class "quizPreviews" ]

                Failure _ ->
                    typography Paragraph p [] "Une erreur s'est produite en chargeant les ludoquiz :-/"

                Loading ->
                    typography Paragraph p [] "Chargement des ludoquiz..."

                NotAsked ->
                    text ""
            ]
        ]
    }


viewQuizPreview : Shared.Model -> QuizPreview -> Html Msg
viewQuizPreview sharedModel quizPreview =
    let
        route =
            Quiz__QuizSlug_String { quizSlug = quizPreview.slug }
                |> Route.toString
    in
    li [ class "quizDetails" ]
        [ a [ href route ]
            [ div [ class "panel quizDetailsElements" ]
                [ typography Title2 h2 [ class "quizTitle" ] quizPreview.title
                , typography DateTime p [ class "quizTime" ] (Time.humanReadableDate sharedModel.timeAndZone quizPreview.publicationDate)
                , viewMaybe
                    (\score ->
                        let
                            toDisplay =
                                if score >= quizPreview.questionsCount then
                                    "✔︎ Vous avez réussi ce LudoQuiz !"

                                else
                                    "Meilleur score : " ++ String.fromInt score ++ "/" ++ String.fromInt quizPreview.questionsCount
                        in
                        typography QuizBestResult p [ class "quizBestResult" ] toDisplay
                    )
                    (getResultForQuiz sharedModel quizPreview.id)
                , node "block-content" [ class "description", property "blocks" quizPreview.description ] []
                ]
            ]
        ]


viewBanner : Html Msg
viewBanner =
    let
        alternativeText =
            "Cliquez ici pour accéder aux nombreux jeux disponibles sur Philibert !"
    in
    li [ class "banner" ]
        [ a [ href philibertLink, target "_blank", onClick PhilibertBannerClicked ]
            [ img [ class "banner--desktop", src philibertBannerUrl, alt alternativeText ] []
            , img [ class "banner--mobile", src philibertMobileBannerUrl, alt alternativeText ] []
            ]
        ]


styles : List Snippet
styles =
    [ Css.class "catchPhrase"
        [ textAlign center ]
    , Css.class "banner"
        [ marginTop Spacing.M
        , borderRadius (px 10)
        , overflow hidden
        , textAlign center
        , Css.descendants
            [ Css.a [ textDecoration none ]
            , Css.class "banner--desktop"
                [ width (pct 100)
                , onSmallScreen
                    [ display none
                    ]
                ]
            , Css.class "banner--mobile"
                [ display none
                , maxWidth (pct 100)
                , onSmallScreen
                    [ display inline
                    ]
                ]
            ]
        ]
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
    , Css.class "quizBestResult"
        [ width (pct 100)
        , marginTop Spacing.XS
        ]
    , Css.class "description"
        [ width (pct 100)
        , marginTop Spacing.S
        ]
    ]
