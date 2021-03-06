module Pages.Quiz.QuizSlug_String exposing (Model, Msg, Params, page)

import Browser.Dom as Dom exposing (getElement)
import Css exposing (alignItems, auto, center, column, display, displayFlex, flexDirection, flexGrow, flexWrap, inlineBlock, int, justifyContent, margin, maxHeight, maxWidth, pct, px, spaceAround, stretch, textAlign, vh, width, wrap)
import Css.Global as Css exposing (Snippet)
import DesignSystem.Button exposing (ButtonSize(..), ButtonType(..), button, buttonLink)
import DesignSystem.Responsive exposing (onSmallScreen)
import DesignSystem.SanityImage exposing (sanityImage)
import DesignSystem.Spacing as Spacing exposing (SpacingSize(..), marginBottom, marginLeft, marginTop, padding2)
import DesignSystem.Typography exposing (TypographyType(..), typography)
import Html.Styled exposing (Html, a, div, h2, img, li, main_, p, text)
import Html.Styled.Attributes exposing (class, css, href, id, src)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Keyed as Keyed
import Id
import List.Extra as List
import List.Nonempty as Nonempty
import Model.Quiz as Quiz exposing (Answer, Question, Quiz, QuizId)
import Model.Result as Result exposing (Result)
import Ports
import RemoteData exposing (RemoteData(..), WebData)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route(..))
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Task
import Utils.Html exposing (viewMaybe)


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
    , sharedModel : Shared.Model
    }


type alias QuizGame =
    { id : QuizId
    , title : String
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
      , sharedModel = sharedModel
      }
    , Quiz.findBySlug QuizFetched params.quizSlug
    )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { model | sharedModel = shared }
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
                                { id = quiz.id
                                , title = quiz.title
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
                                , Cmd.batch
                                    [ scrollTo "currentQuestion"
                                    , logQuizCompletedIfNeeded newState
                                    , saveScoreIfNeeded quizGame.id newState
                                    ]
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


saveScoreIfNeeded : QuizId -> State -> Cmd msg
saveScoreIfNeeded id state =
    case state of
        InProgress _ ->
            Cmd.none

        Done { results } ->
            let
                score =
                    List.count (\answeredQuestion -> answeredQuestion.answerStatus == Correct) results
            in
            Result.encode (Result id score)
                |> Ports.storeResult


scrollTo : String -> Cmd Msg
scrollTo id =
    getElement id
        |> Task.andThen (\{ element } -> Dom.setViewport 0 element.y)
        |> Task.attempt (always NoOp)


subscriptions : Model -> Sub Msg
subscriptions _ =
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
                        , img [ src (quiz.image ++ "?w=200&fit=max"), css [ marginBottom Spacing.M ], class "quizImage" ] []
                        ]
                    , case quiz.state of
                        InProgress state ->
                            viewQuestion model.sharedModel (List.length state.answered + 1 + List.length state.remaining) (List.length state.answered + 1) state.current

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


viewQuestion : Shared.Model -> Int -> Int -> Question -> Html Msg
viewQuestion sharedModel questionsCount number question =
    Keyed.node "div"
        []
        [ ( String.fromInt number
          , div [ class "question panel", id "currentQuestion" ]
                [ typography Title2 p [ css [ marginBottom Spacing.M ] ] ("(" ++ String.fromInt number ++ "/" ++ String.fromInt questionsCount ++ ") " ++ question.question)
                , viewMaybe (sanityImage sharedModel [ class "questionImage" ]) question.image
                , Nonempty.toList question.answers
                    |> List.map (\answer -> ( Id.to answer.id, viewAnswer answer ))
                    |> Keyed.ul [ class "answers" ]
                ]
          )
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
        [ viewResultComment results
        , typography HeroText p [ class "score", css [ marginTop L ] ] ("Votre score : " ++ String.fromInt score ++ "/" ++ String.fromInt (List.length results))
        , buttonLink Secondary Large restartRoute [] [ text "Réessayer" ]
        ]


viewResultComment : List AnsweredQuestion -> Html Msg
viewResultComment results =
    let
        correctAnswersCount =
            List.count (\answeredQuestion -> answeredQuestion.answerStatus == Correct) results

        questionsCount =
            List.length results

        ratio =
            if questionsCount == 0 then
                0

            else
                toFloat correctAnswersCount / toFloat questionsCount
    in
    if ratio < 0.2 then
        typography HeroText div [] "\u{1F97A} Je suis sûr que vous pouvez faire mieux ! On retente ?"

    else if ratio < 0.4 then
        typography HeroText div [] "😕 Pas terrible... Heureusement, vous avez le droit à une seconde chance !"

    else if ratio < 0.6 then
        typography HeroText div [] "🙂 Quelques lacunes, mais c'est un bon début !"

    else if ratio < 0.8 then
        typography HeroText div [] "👍 Pas mal ! Retentez ce LudoQuiz pour améliorer votre score !"

    else if ratio < 1 then
        typography HeroText div [] "🎉 Excellent ! Vous êtes prêt à tenter le perfect !"

    else
        typography HeroText div [] "🏆 Félicitations, c'est un sans faute ! Il est temps de relever nos autres LudoQuiz !"


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
