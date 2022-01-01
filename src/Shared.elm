module Shared exposing (Confirm, Flags, Model, Msg, StoredProjects(..), init, projects, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html.Styled exposing (Html)
import Libs.Json.Decode as D
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Theme exposing (Theme)
import Models.Project exposing (Project)
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Task
import Time


type alias Flags =
    { now : Int }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
    , theme : Theme
    , projects : StoredProjects
    }


type alias Confirm msg =
    { color : Color
    , icon : Icon
    , title : String
    , message : Html msg
    , confirm : String
    , cancel : String
    , onConfirm : Cmd msg
    }


type StoredProjects
    = Loading
    | Loaded (List Project)


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix
    | JsMessage JsMsg


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    ( { zone = Time.utc
      , now = Time.millisToPosix flags.now
      , theme = { color = Color.indigo }
      , projects = Loading
      }
    , Cmd.batch
        [ Time.here |> Task.perform ZoneChanged
        , Ports.loadProjects
        ]
    )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        ZoneChanged zone ->
            ( { model | zone = zone }, Cmd.none )

        TimeChanged time ->
            ( { model | now = time }, Cmd.none )

        JsMessage (GotProjects ( errors, prjs )) ->
            ( { model | projects = Loaded (prjs |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))) }
            , Cmd.batch
                (errors
                    |> List.concatMap
                        (\( name, err ) ->
                            [ Ports.toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ D.errorToHtml err)
                            , Ports.trackJsonError "decode-project" err
                            ]
                        )
                )
            )

        JsMessage _ ->
            ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ Time.every (10 * 1000) TimeChanged
        , Ports.onJsMessage JsMessage
        ]


projects : Model -> List Project
projects model =
    case model.projects of
        Loading ->
            []

        Loaded prjs ->
            prjs
