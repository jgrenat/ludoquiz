module DesignSystem.Global exposing (styles)

import Css exposing (auto, backgroundColor, backgroundImage, backgroundSize, block, borderRadius, boxShadow, boxShadow5, center, contain, cover, display, fontStyle, fontWeight, height, int, italic, margin, maxWidth, minHeight, none, pct, px, rgba, textAlign, textDecoration, underline, url)
import Css.Global as Css exposing (Snippet, em)
import DesignSystem.Button exposing (ButtonSize(..))
import DesignSystem.Colors as Colors
import DesignSystem.Spacing exposing (SpacingSize(..), marginBottom, padding2)
import DesignSystem.Typography as FontSize exposing (FontFamily(..), fontFamily, fontSize)


styles : List Snippet
styles =
    [ Css.html
        [ height (pct 100)
        ]
    , Css.body
        [ height (pct 100)
        , fontFamily Lato
        , backgroundImage (url "/images/background.svg")
        , backgroundSize cover
        ]
    , Css.header
        [ textAlign center
        , display block
        , marginBottom M
        ]
    , Css.class "container"
        [ maxWidth (px 800)
        , margin auto
        , backgroundColor Colors.containerBackground
        , padding2 M M
        , minHeight (pct 100)
        , boxShadow5 (px 0) (px 1) (px 20) (px -4) Colors.containerShadow
        ]
    , Css.class "panel"
        [ backgroundColor Colors.panelColor
        , padding2 S S
        , boxShadow5 (px 0) (px 1) (px 10) (px -4) Colors.containerShadow
        , borderRadius (px 10)
        ]
    , Css.typeSelector "block-content"
        [ Css.descendants
            [ Css.strong
                [ fontWeight (int 900)
                ]
            , em
                [ fontStyle italic
                ]
            , Css.a
                [ textDecoration underline
                , Css.hover [ textDecoration none ]
                ]
            ]
        ]
    ]
