module PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml, setCanvas, setCurrentLayout, setLayout, setLayouts, setPosition, setProject, setProjectWithCmd, setRelations, setSettings, setSwitch, setTableInList, setTableList, setTables, setTime)

import Json.Decode as Decode
import Libs.Bool as B
import Libs.Delta exposing (Delta)
import Libs.Maybe as M
import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)


setTime : (t -> t) -> { item | time : t } -> { item | time : t }
setTime transform item =
    { item | time = item.time |> transform }


setSwitch : (s -> s) -> { item | switch : s } -> { item | switch : s }
setSwitch transform item =
    { item | switch = item.switch |> transform }


setProject : (p -> p) -> { item | project : Maybe p } -> { item | project : Maybe p }
setProject transform item =
    { item | project = item.project |> Maybe.map transform }


setProjectWithCmd : (p -> ( p, Cmd msg )) -> { item | project : Maybe p } -> ( { item | project : Maybe p }, Cmd msg )
setProjectWithCmd transform item =
    item.project |> M.mapOrElse (\p -> p |> transform |> Tuple.mapFirst (\project -> { item | project = Just project })) ( item, Cmd.none )


setRelations : (r -> r) -> { item | relations : r } -> { item | relations : r }
setRelations transform item =
    { item | relations = item.relations |> transform }


setLayout : (l -> l) -> { item | layout : l } -> { item | layout : l }
setLayout transform item =
    { item | layout = item.layout |> transform }


setCurrentLayout : (l -> l) -> { m | project : Maybe { p | layout : l } } -> { m | project : Maybe { p | layout : l } }
setCurrentLayout transform item =
    setProject (setLayout transform) item


setCanvas : (l -> l) -> { item | canvas : l } -> { item | canvas : l }
setCanvas transform item =
    { item | canvas = item.canvas |> transform }


setTables : (t -> t) -> { item | tables : t } -> { item | tables : t }
setTables transform item =
    { item | tables = item.tables |> transform }


setTableList : (table -> Bool) -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
setTableList predicate transform item =
    setTables (\tables -> tables |> List.map (\t -> B.cond (predicate t) (transform t) t)) item


setTableInList : (table -> comparable) -> comparable -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
setTableInList get id transform item =
    setTableList (\t -> get t == id) transform item


setLayouts : (l -> l) -> { item | layouts : l } -> { item | layouts : l }
setLayouts transform item =
    { item | layouts = item.layouts |> transform }


setPosition : Delta -> ZoomLevel -> { item | position : Position } -> { item | position : Position }
setPosition delta zoom item =
    { item | position = Position (item.position.left + (delta.dx / zoom)) (item.position.top + (delta.dy / zoom)) }


setSettings : (s -> s) -> { item | settings : s } -> { item | settings : s }
setSettings transform item =
    { item | settings = item.settings |> transform }


decodeErrorToHtml : Decode.Error -> String
decodeErrorToHtml error =
    "<pre>" ++ Decode.errorToString error ++ "</pre>"



--pure : a -> ( a, Cmd msg )
--pure a =
--    ( a, Cmd.none )
--
--
--map : (a -> b) -> ( a, Cmd msg ) -> ( b, Cmd msg )
--map f ( a, cmd ) =
--    ( f a, cmd )
--
--
--andThen : (a -> ( b, Cmd msg )) -> ( a, Cmd msg ) -> ( b, Cmd msg )
--andThen f ( a, cmd1 ) =
--    f a |> Tuple.mapSecond (\cmd2 -> Cmd.batch [ cmd1, cmd2 ])
