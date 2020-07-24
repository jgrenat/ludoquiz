module DesignSystem.Responsive exposing (onMobile)

import Css exposing (Style, px)
import Css.Media exposing (only, screen)


onMobile : List Style -> Style
onMobile styles =
    Css.Media.withMedia
        [ only screen [ Css.Media.maxWidth (px 768) ]
        ]
        styles
