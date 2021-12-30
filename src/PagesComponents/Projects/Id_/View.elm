module PagesComponents.Projects.Id_.View exposing (viewProject)

import Components.Atoms.Styles as Styles
import Components.Molecules.Modal as Modal
import Components.Molecules.Toast as Toast
import Components.Slices.NotFound as NotFound
import Conf
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes exposing (class, css)
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.Theme exposing (Theme)
import Libs.Task as T
import Models.Project exposing (Project)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..))
import PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)
import PagesComponents.Projects.Id_.Views.Erd exposing (viewErd)
import PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)
import Shared exposing (Confirm, StoredProjects(..))
import Tailwind.Utilities as Tw


viewProject : Shared.Model -> Model -> List (Html Msg)
viewProject shared model =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100, Tw.overflow_hidden ], Global.selector "body" [ Tw.h_full ] ]
    , Styles.global
    , case shared.projects of
        Loading ->
            viewLoader shared.theme

        Loaded projects ->
            model.project |> M.mapOrElse (viewApp shared.theme model projects) (viewNotFound shared.theme)
    , viewConfirm model.confirm
    , viewToasts shared.theme model.toasts
    ]


viewApp : Theme -> Model -> List Project -> Project -> Html Msg
viewApp theme model storedProjects project =
    div [ class "tw-app" ]
        [ viewNavbar theme model.openedDropdown storedProjects project model.navbar
        , viewErd theme model project
        , viewCommands theme model.openedDropdown model.cursorMode project.layout.canvas
        ]


viewLoader : Theme -> Html msg
viewLoader theme =
    div [ class "tw-loader", css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.h_screen ] ]
        [ div [ css [ Tw.animate_spin, Tw.rounded_full, Tw.h_32, Tw.w_32, Tw.border_t_2, Tw.border_b_2, Color.border theme.color 500 ] ] []
        ]


viewNotFound : Theme -> Html msg
viewNotFound theme =
    NotFound.simple theme
        { brand =
            { img = { src = "/logo.png", alt = "Azimutt" }
            , link = { url = Route.toHref Route.Home_, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Project not found."
        , message = "Sorry, we couldn't find the project you’re looking for."
        , link = { url = Route.toHref Route.Projects, text = "Go back to dashboard" }
        , footer =
            [ { url = Conf.constants.azimuttGithub ++ "/discussions", text = "Contact Support" }
            , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
            , { url = Route.toHref Route.Blog, text = "Blog" }
            ]
        }


viewConfirm : Confirm Msg -> Html Msg
viewConfirm c =
    div [ class "tw-confirm" ]
        [ Modal.confirm
            { id = Conf.ids.confirm
            , icon = c.icon
            , color = c.color
            , title = c.title
            , message = c.message
            , confirm = c.confirm
            , cancel = c.cancel
            , onConfirm = ConfirmAnswer True c.onConfirm
            , onCancel = ConfirmAnswer False (T.send (Noop "confirm cancel"))
            }
            c.isOpen
        ]


viewToasts : Theme -> List Toast.Model -> Html Msg
viewToasts theme toasts =
    div [ class "tw-toasts" ] [ Toast.container theme toasts ToastHide ]
