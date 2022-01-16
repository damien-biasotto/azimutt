module PagesComponents.App.Updates.Layout exposing (handleLayout)

import Dict
import Libs.Bool as B
import Libs.Dict as D
import Libs.Maybe as M
import Models.Project exposing (Project)
import Models.Project.Layout as Layout
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.App.Models exposing (LayoutMsg(..), Model, Msg)
import Ports
import Services.Lenses exposing (setLayout, setLayouts, setProject, setProjectWithCmd)
import Time
import Track


type alias Model x =
    { x
        | newLayout : Maybe LayoutName
        , project : Maybe Project
    }


handleLayout : LayoutMsg -> Model x -> ( Model x, Cmd Msg )
handleLayout msg model =
    case msg of
        LNew name ->
            ( { model | newLayout = B.cond (String.length name == 0) Nothing (Just name) }, Cmd.none )

        LCreate name ->
            { model | newLayout = Nothing } |> setProjectWithCmd (createLayout name)

        LLoad name ->
            model |> setProjectWithCmd (loadLayout name)

        LUnload ->
            ( model |> setProject unloadLayout, Cmd.none )

        LUpdate name ->
            model |> setProjectWithCmd (updateLayout name)

        LDelete name ->
            model |> setProjectWithCmd (deleteLayout name)


createLayout : LayoutName -> Project -> ( Project, Cmd Msg )
createLayout name project =
    -- TODO check that layout name does not already exist
    { project | usedLayout = Just name }
        |> setLayouts (Dict.update name (\_ -> Just project.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ Ports.saveProject newSchema, Ports.track (Track.createLayout project.layout) ] ))


loadLayout : LayoutName -> Project -> ( Project, Cmd Msg )
loadLayout name project =
    project.layouts
        |> Dict.get name
        |> M.mapOrElse
            (\layout ->
                ( { project | usedLayout = Just name } |> setLayout (\_ -> layout)
                , Cmd.batch [ layout.tables |> List.map .id |> Ports.observeTablesSize, Ports.activateTooltipsAndPopovers, Ports.track (Track.loadLayout layout) ]
                )
            )
            ( project, Cmd.none )


unloadLayout : Project -> Project
unloadLayout project =
    { project | usedLayout = Nothing }


updateLayout : LayoutName -> Project -> ( Project, Cmd Msg )
updateLayout name project =
    -- TODO check that layout name already exist
    { project | usedLayout = Just name }
        |> setLayouts (Dict.update name (\_ -> Just project.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ Ports.saveProject newSchema, Ports.track (Track.updateLayout project.layout) ] ))


deleteLayout : LayoutName -> Project -> ( Project, Cmd Msg )
deleteLayout name project =
    { project | usedLayout = B.cond (project.usedLayout == Just name) Nothing (Just name) }
        |> setLayouts (Dict.update name (\_ -> Nothing))
        |> (\newSchema -> ( newSchema, Cmd.batch [ Ports.saveProject newSchema, Ports.track (Track.deleteLayout (project.layouts |> D.getOrElse name (Layout.init (Time.millisToPosix 0)))) ] ))
