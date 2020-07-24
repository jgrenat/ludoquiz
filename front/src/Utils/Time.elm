module Utils.Time exposing (TimeAndZone, defaultTimeAndZone, fromTimeAndZone, humanReadableDate, updateTime)

import DateFormat
import DateFormat.Languages
import DateFormat.Relative exposing (RelativeTimeOptions)
import Time exposing (Posix, Zone)
import Time.Extra as Time exposing (Interval(..))


type TimeAndZone
    = TimeAndZone { time : Posix, zone : Zone }


defaultTimeAndZone : TimeAndZone
defaultTimeAndZone =
    TimeAndZone { time = Time.millisToPosix 0, zone = Time.utc }


fromTimeAndZone : Posix -> Zone -> TimeAndZone
fromTimeAndZone time zone =
    TimeAndZone { time = time, zone = zone }


updateTime : TimeAndZone -> Posix -> TimeAndZone
updateTime (TimeAndZone { zone }) time =
    TimeAndZone { time = time, zone = zone }


humanReadableDate : TimeAndZone -> Posix -> String
humanReadableDate (TimeAndZone { time, zone }) posix =
    let
        differenceInDays =
            Time.diff Day zone posix time
    in
    if differenceInDays < 3 then
        DateFormat.Relative.relativeTimeWithOptions frenchRelativeOptions time posix

    else
        DateFormat.formatWithLanguage
            DateFormat.Languages.french
            [ DateFormat.dayOfMonthFixed
            , DateFormat.text " "
            , DateFormat.monthNameFull
            , DateFormat.text " "
            , DateFormat.yearNumber
            ]
            zone
            time



-- French for date-format


frenchRelativeOptions : RelativeTimeOptions
frenchRelativeOptions =
    { someSecondsAgo = frenchSomeSecondsAgo
    , someMinutesAgo = frenchSomeMinutesAgo
    , someHoursAgo = frenchSomeHoursAgo
    , someDaysAgo = frenchSomeDaysAgo
    , someMonthsAgo = frenchSomeMonthsAgo
    , someYearsAgo = frenchSomeYearsAgo
    , rightNow = frenchRightNow
    , inSomeSeconds = frenchInSomeSeconds
    , inSomeMinutes = frenchInSomeMinutes
    , inSomeHours = frenchInSomeHours
    , inSomeDays = frenchInSomeDays
    , inSomeMonths = frenchInSomeMonths
    , inSomeYears = frenchInSomeYears
    }


frenchRightNow : String
frenchRightNow =
    "à l'instant"


frenchSomeSecondsAgo : Int -> String
frenchSomeSecondsAgo seconds =
    if seconds < 30 then
        frenchRightNow

    else
        "moins de " ++ String.fromInt (ceiling (toFloat seconds / 10) * 10) ++ " secondes"


frenchSomeMinutesAgo : Int -> String
frenchSomeMinutesAgo minutes =
    if minutes < 2 then
        "1 minute"

    else
        String.fromInt minutes ++ " minutes"


frenchSomeHoursAgo : Int -> String
frenchSomeHoursAgo hours =
    if hours < 2 then
        "une heure"

    else
        String.fromInt hours ++ " heures"


frenchSomeDaysAgo : Int -> String
frenchSomeDaysAgo days =
    if days < 2 then
        "hier"

    else
        String.fromInt days ++ " jours"


frenchSomeMonthsAgo : Int -> String
frenchSomeMonthsAgo months =
    String.fromInt months ++ " mois"


frenchSomeYearsAgo : Int -> String
frenchSomeYearsAgo years =
    if years < 2 then
        "1 an"

    else
        String.fromInt years ++ " ans"


frenchInSomeSeconds : Int -> String
frenchInSomeSeconds seconds =
    if seconds < 30 then
        "dans quelques secondes"

    else
        "dans " ++ String.fromInt seconds ++ " secondes"


frenchInSomeMinutes : Int -> String
frenchInSomeMinutes minutes =
    if minutes < 2 then
        "dans une minute"

    else
        "dans " ++ String.fromInt minutes ++ " minutes"


frenchInSomeHours : Int -> String
frenchInSomeHours hours =
    if hours < 2 then
        "dans une heure"

    else
        "dans " ++ String.fromInt hours ++ " heures"


frenchInSomeDays : Int -> String
frenchInSomeDays days =
    if days < 2 then
        "demain"

    else
        "dans " ++ String.fromInt days ++ " jours"


frenchInSomeMonths : Int -> String
frenchInSomeMonths months =
    if months < 2 then
        "le mois prochain"

    else
        "dans " ++ String.fromInt months ++ " mois"


frenchInSomeYears : Int -> String
frenchInSomeYears years =
    if years < 2 then
        "dans un an"

    else
        "dans " ++ String.fromInt years ++ " ans"
