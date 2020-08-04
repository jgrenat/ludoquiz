module Pages.Quiz.QuizSlug_String exposing (Model, Msg, Params, page)

import Browser.Dom as Dom exposing (getElement)
import Css exposing (alignItems, auto, center, color, column, display, displayFlex, flexDirection, flexGrow, flexWrap, inlineBlock, int, justifyContent, margin, maxHeight, maxWidth, none, pct, px, spaceAround, stretch, textAlign, textDecoration, vh, width, wrap)
import Css.Global as Css exposing (Snippet)
import DesignSystem.Button exposing (ButtonSize(..), ButtonType(..), button, buttonLink)
import DesignSystem.Colors as Colors
import DesignSystem.Responsive exposing (onSmallScreen)
import DesignSystem.Spacing as Spacing exposing (SpacingSize(..), marginBottom, marginLeft, marginTop, padding2)
import DesignSystem.Typography exposing (TypographyType(..), typography)
import Html.Styled exposing (Html, a, div, h2, img, li, main_, p, text, ul)
import Html.Styled.Attributes exposing (class, css, href, id, src)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Keyed as Keyed
import Id
import List.Extra as List
import List.Nonempty as Nonempty
import Model.Quiz as Quiz exposing (Answer, Question, Quiz)
import Ports
import RemoteData exposing (RemoteData(..), WebData)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route(..))
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Task
import Utils.Html exposing (viewMaybe)
import Utils.Time exposing (TimeAndZone)


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
    { quizSlug : String }


type alias Model =
    { slug : String
    , quiz : WebData QuizGame
    , timeAndZone : TimeAndZone
    }


type alias QuizGame =
    { title : String
    , image : String
    , state : State
    }


type State
    = InProgress InProgressState
    | Done { results : List AnsweredQuestion }


type alias InProgressState =
    { answered : List AnsweredQuestion
    , current : Question
    , remaining : List Question
    }


type alias AnsweredQuestion =
    { question : Question
    , answerStatus : AnswerStatus
    }


type AnswerStatus
    = Correct
    | Incorrect


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init sharedModel { params } =
    ( { slug = params.quizSlug
      , quiz = Loading
      , timeAndZone = sharedModel.timeAndZone
      }
    , Quiz.findBySlug QuizFetched params.quizSlug
    )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { model | timeAndZone = shared.timeAndZone }
    , Cmd.none
    )



-- UPDATE


type Msg
    = QuizFetched (WebData Quiz)
    | AnswerQuestion Answer
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        QuizFetched quizData ->
            let
                quizStatus =
                    case quizData of
                        Success quiz ->
                            Success
                                { title = quiz.title
                                , image = quiz.image
                                , state =
                                    InProgress
                                        { answered = []
                                        , current = Nonempty.head quiz.questions
                                        , remaining = Nonempty.tail quiz.questions
                                        }
                                }

                        NotAsked ->
                            NotAsked

                        Loading ->
                            Loading

                        Failure failure ->
                            Failure failure
            in
            ( { model | quiz = quizStatus }, Cmd.none )

        AnswerQuestion answer ->
            model.quiz
                |> RemoteData.map
                    (\quizGame ->
                        case quizGame.state of
                            InProgress state ->
                                let
                                    newState =
                                        answerQuestion state answer
                                in
                                ( { model | quiz = Success { quizGame | state = newState } }
                                , Cmd.batch [ scrollTo "currentQuestion", logQuizCompletedIfNeeded newState ]
                                )

                            Done _ ->
                                ( model, Cmd.none )
                    )
                |> RemoteData.withDefault ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


answerQuestion : InProgressState -> Answer -> State
answerQuestion state answer =
    let
        answerStatus =
            if answer.isCorrect then
                Correct

            else
                Incorrect
    in
    case state.remaining of
        [] ->
            Done
                { results =
                    { question = state.current, answerStatus = answerStatus }
                        :: state.answered
                        |> List.reverse
                }

        first :: remaining ->
            InProgress
                { state
                    | answered = { question = state.current, answerStatus = answerStatus } :: state.answered
                    , current = first
                    , remaining = remaining
                }


logQuizCompletedIfNeeded : State -> Cmd Msg
logQuizCompletedIfNeeded state =
    case state of
        InProgress _ ->
            Cmd.none

        Done _ ->
            Ports.logEvent "QuizCompleted"


scrollTo : String -> Cmd Msg
scrollTo id =
    getElement id
        |> Task.andThen (\{ element } -> Dom.setViewport 0 element.y)
        |> Task.attempt (always NoOp)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Quiz"
    , body =
        [ Css.global styles
        , case model.quiz of
            Success quiz ->
                main_ []
                    [ div [ class "quizIdentity" ]
                        [ typography Title1 h2 [ class "quizName", css [ marginBottom Spacing.M ] ] quiz.title
                        , img [ src quiz.image, css [ marginBottom Spacing.M ], class "quizImage" ] []
                        ]
                    , case quiz.state of
                        InProgress state ->
                            viewQuestion (List.length state.answered + 1 + List.length state.remaining) (List.length state.answered + 1) state.current

                        Done { results } ->
                            viewResult model.slug results
                    ]

            Failure _ ->
                text "An error occurred :-/"

            Loading ->
                text "Loading"

            NotAsked ->
                text "Not asked"
        , viewHomeLink
        ]
    }


viewQuestion : Int -> Int -> Question -> Html Msg
viewQuestion questionsCount number question =
    div [ class "question panel", id "currentQuestion" ]
        [ typography Title2 p [ css [ marginBottom Spacing.M ] ] ("(" ++ String.fromInt number ++ "/" ++ String.fromInt questionsCount ++ ") " ++ question.question)
        , viewMaybe (\image -> img [ src image, class "questionImage" ] []) question.image
        , Nonempty.toList question.answers
            |> List.map (\answer -> ( Id.to answer.id, viewAnswer answer ))
            |> Keyed.ul [ class "answers" ]
        ]


viewAnswer : Answer -> Html Msg
viewAnswer answer =
    li [ class "answer" ]
        [ button Secondary
            Large
            [ css [ width (pct 100) ], onClick (AnswerQuestion answer) ]
            [ text answer.answer
            ]
        ]


viewResult : String -> List AnsweredQuestion -> Html Msg
viewResult slug results =
    let
        score =
            List.count (\answeredQuestion -> answeredQuestion.answerStatus == Correct) results

        restartRoute =
            Quiz__QuizSlug_String { quizSlug = slug }
                |> Route.toString
    in
    div [ class "panel result" ]
        [ typography HeroText p [ class "score" ] ("Votre score : " ++ String.fromInt score ++ "/" ++ String.fromInt (List.length results))
        , buttonLink Secondary Large restartRoute [] [ text "Réessayer" ]
        ]


viewHomeLink : Html Msg
viewHomeLink =
    div [ class "homeLink" ]
        [ typography Paragraph a [ href "/" ] "< Retour"
        ]



-- STYLES


styles : List Snippet
styles =
    [ Css.class "quizIdentity"
        [ displayFlex
        , alignItems center
        , flexWrap wrap
        , justifyContent center
        ]
    , Css.class "quizName"
        [ flexGrow (int 1)
        ]
    , Css.class "quizImage"
        [ width (pct 100)
        , maxWidth (px 200)
        , marginLeft Spacing.S
        ]
    , Css.class "question"
        [ displayFlex
        , flexDirection column
        ]
    , Css.class "questionImage"
        [ maxWidth (pct 100)
        , maxHeight (vh 50)
        , margin auto
        , display inlineBlock
        ]
    , Css.class "answers"
        [ displayFlex
        , flexWrap wrap
        , justifyContent spaceAround
        , alignItems stretch
        , marginTop Spacing.S
        , Css.children
            [ Css.class "answer"
                [ displayFlex
                , alignItems center
                , padding2 Spacing.S Spacing.M
                , width (pct 50)
                , onSmallScreen [ width (pct 100) ]
                ]
            ]
        ]
    , Css.class "result"
        [ textAlign center
        ]
    , Css.class "score"
        [ Spacing.marginBottom Spacing.S
        ]
    , Css.class "homeLink"
        [ Spacing.marginTop Spacing.L
        , Spacing.marginBottom Spacing.S
        , textAlign center
        ]
    ]
