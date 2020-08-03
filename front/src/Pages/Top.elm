module Pages.Top exposing (Model, Msg, Params, page)

import Css exposing (borderRadius, center, color, display, displayFlex, flexWrap, hidden, inline, justifyContent, maxWidth, none, overflow, pct, px, spaceBetween, textAlign, textDecoration, width, wrap)
import Css.Global as Css exposing (Snippet)
import DesignSystem.Colors as Colors
import DesignSystem.Responsive exposing (onSmallScreen)
import DesignSystem.Spacing as Spacing exposing (marginTop)
import DesignSystem.Typography exposing (TypographyType(..), typography)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (alt, class, href, property, src, target)
import List.Extra as List
import Model.Quiz as Quiz exposing (QuizPreview)
import RemoteData exposing (RemoteData(..), WebData)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route(..))
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.Time as Time exposing (TimeAndZone)


philibertLink : String
philibertLink =
    "https://www.philibertnet.com/fr/#ae356-12"


philibertBannerUrl : String
philibertBannerUrl =
    "https://lb.affilae.com/imp/5bf52e77e2891d7d00f2e8af/5f1fece020fada696401c689/5e135681b53a17179f2aeaa1/https://s3-eu-west-1.amazonaws.com/aeup/uploads/programs/5bf52e77e2891d7d00f2e8af/elements/5e135681b53a17179f2aea9f.jpg"


philibertMobileBannerUrl : String
philibertMobileBannerUrl =
    "https://lb.affilae.com/imp/5bf52e77e2891d7d00f2e8af/5f1fece020fada696401c689/5e135b4cb53a17179f2aefc5/https://s3-eu-west-1.amazonaws.com/aeup/uploads/programs/5bf52e77e2891d7d00f2e8af/elements/5e135b4cb53a17179f2aefc3.jpg"


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
                                    viewQuizPreview model.timeAndZone quizPreview

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


viewBanner : Html Msg
viewBanner =
    let
        alternativeText =
            "Cliquez ici pour accéder aux nombreux jeux disponibles sur Philibert !"
    in
    li [ class "banner" ]
        [ a [ href philibertLink, target "_blank" ]
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
    , Css.class "description"
        [ width (pct 100)
        , marginTop Spacing.S
        ]
    ]
