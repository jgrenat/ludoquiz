module DesignSystem.SanityImage exposing (sanityImage)

import Html.Styled exposing (Attribute, Html, img)
import Html.Styled.Attributes exposing (src)
import Shared


sanityImage : Shared.Model -> List (Attribute msg) -> String -> Html msg
sanityImage sharedModel attributes imageLink =
    let
        linkWithParameters =
            case sharedModel.screenSize of
                Just { width, height } ->
                    let
                        imageHeight =
                            ceiling ((height / 2) / 100) * 100

                        imageWidth =
                            ceiling ((min width 800 - (24 * 2)) / 100) * 100
                    in
                    imageLink ++ "?w=" ++ String.fromInt imageWidth ++ "&h=" ++ String.fromInt imageHeight ++ "&fit=max"

                Nothing ->
                    imageLink
    in
    img (src linkWithParameters :: attributes) []
