module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src)

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick, on)

import Random
import Time
import Process
import Task

import Json.Decode as Decode

---- MODEL ----

type alias Model =
     { boxes : List SmartRectangle
     , level : Int
     , timer : Int
     }


init : ( Model, Cmd Msg )
init =
    ( {boxes = [ ], level = 1, timer = 0}, Cmd.batch (List.range 1 10 |> List.map (\level -> Random.generate GenerateRandomRectangles (levelListGenerator level))))


xRandomMaximum : Int
xRandomMaximum = 800 - rectangleWidth

levelListGenerator : Int -> Random.Generator (List SmartRectangle)
levelListGenerator level = 
    let
        multiplicationFactor = 5 

        finalId id = id + previousListTotal

        listTotal level_parameter =  10 + level_parameter  * multiplicationFactor            

        previousListTotal = if level == 1 then
                              1
                            else 
                                listTotal (level - 1)
    in        
    Random.list (listTotal level) (randomSmarterRectangle level) |> Random.map  (List.indexedMap (\id x -> {id = ( finalId id), zapped = x.zapped, xPosition = x.xPosition, startingTime = x.startingTime, duration = x.duration}))
                            
                                                            

randomSmarterRectangle : Int -> Random.Generator RectangleWithoutId
randomSmarterRectangle level = Random.map3
    (\x y z -> RectangleWithoutId False x y z)
    (Random.int rectangleWidth xRandomMaximum) -- x position
    (startTimeByLevel level)       -- starting time
    (Random.int 4 ((maxDuration))) -- duration


startTimeByLevel : Int -> Random.Generator Int
startTimeByLevel level =
    Random.map (\r -> r + (level - 1)* 10) (Random.int 0 8)


type alias RectangleWithoutId = 
 {
    zapped : Bool
  , xPosition : Int 
  , startingTime : Int
  , duration : Int
 }

type alias SmartRectangle = 
  { id : Int
  , zapped : Bool
  , xPosition : Int 
  , startingTime : Int
  , duration : Int
  }

---- UPDATE ----

type Msg
    = Zap Int
    | Die Int
    | GenerateRandomRectangles (List SmartRectangle)
    | EndLevel
    | Tick Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of 
        Zap indexNo ->
            let
                updateZappedElement smartRectangle = if smartRectangle.id == indexNo then
                                                        {smartRectangle | zapped = True}
                                                     else 
                                                        smartRectangle

                areAllZapped rectangle = rectangle.zapped == True
            in
            if List.all (areAllZapped) (List.map updateZappedElement model.boxes) then
                ( {model | boxes = []}, Cmd.none )
            else
                ( {model | boxes = List.map updateZappedElement model.boxes}, Cmd.none )
        GenerateRandomRectangles rectangles ->
            ({model | boxes = model.boxes ++ rectangles}, Cmd.none)
        EndLevel ->
            (model, Cmd.none) 
        Tick newTime ->
            ( { model | timer = model.timer + 1 }, Cmd.none)
        Die indexNo ->
            (model, Cmd.none)


view : Model -> Html Msg
view model =        
    div []
        [   svg
            [ width "800"
            , height "700"
            , viewBox "0 0 800 700"
            ]
            (List.map (displayRectangle model) model.boxes )
        ]

displayRectangle : Model -> SmartRectangle -> Svg Msg
displayRectangle model smartRectangle  =
    if smartRectangle.zapped == False then
        svg [] [  encompassedRectangle smartRectangle.xPosition smartRectangle.startingTime smartRectangle.id smartRectangle.duration model
               ]
    else
        Svg.text ""

rectangleWidth : Int
rectangleWidth  = 100

rectangleHeight : Int
rectangleHeight = 100

startingBoxPosition : Int
startingBoxPosition = -100 - rectangleHeight

encompassedRectangle : Int -> Int -> Int -> Int -> Model -> Svg Msg
encompassedRectangle xPosition startingTime id duration model =
    let     
        animationFactor = animate [ from (String.fromInt startingBoxPosition), to "800", begin (String.fromInt startingTime), dur ((String.fromInt duration) ++ "s"), repeatCount "1", attributeName "y", onEnd (Die id)] [] 
    in  
        svg []
            [ rect
                [ width (String.fromInt rectangleWidth)
                , height (String.fromInt rectangleHeight)
                , fill "dodgerblue"
                , onClick (Zap id)
                , x (String.fromInt xPosition)
                , y (String.fromInt startingBoxPosition)
                , rx "15", ry "15"
                ]
                [ animationFactor ]
            , text_ [] [Svg.text (String.fromInt id), animationFactor]  
            ]
      

maxDuration : Int
maxDuration = 10


---- EVENTS
onEnd : msg -> Attribute msg
onEnd message =
  on "end" (Decode.succeed message)

---- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none
        -- Time.every 1000 Tick 

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
    }
