module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src)

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)

import Random
import Time
import Process
import Task

---- Parameterise the levels.
{-
    more boxes more level.
    faster speeds
    longer time periods per levels.
-}

---- MODEL ----

type alias Model =
     { boxes : List SmartRectangle
     , level : Int
     , timer : Int
     }


init : ( Model, Cmd Msg )
init =
    ( {boxes = [ ], level = 1, timer = 0}, Random.generate GenerateRandomRectangles (initialRectangles 0))

startingTimeRandomMax : Int
startingTimeRandomMax = 6

xRandomMaximum : Int
xRandomMaximum = 800 - rectangleWidth

randomRectangle : Random.Generator RectangleWithoutId
randomRectangle = Random.map3
    (\x y z -> RectangleWithoutId False x y z)
    (Random.int rectangleWidth xRandomMaximum)
    (Random.int 0 startingTimeRandomMax)
    (Random.int 4 ((maxDurationOfLevel // 1000)))

hasCrossedTheFinishLine : SmartRectangle -> Bool
hasCrossedTheFinishLine rectange = 
    False 

initialRectangles : Int -> Random.Generator (List SmartRectangle)
initialRectangles endingNumber =
    Random.list 10 randomRectangle |> Random.map (List.indexedMap (\i x -> {id = i + endingNumber, zapped = x.zapped, xPosition = x.xPosition, startingTime = x.startingTime, duration = x.duration}))

--  Random.map (List.indexedMap (\id x -> {x | id = id}) ) (Random.list 10 randomRectangle)
generateRectangle : Model -> Random.Generator SmartRectangle
generateRectangle model = 
    randomRectangle |> Random.map (\rectangelWithoutId -> convertToRectangleWithId (List.length model.boxes) rectangelWithoutId)


convertToRectangleWithId : Int -> RectangleWithoutId -> SmartRectangle
convertToRectangleWithId id rectangelWithoutId =
    SmartRectangle id rectangelWithoutId.zapped rectangelWithoutId.xPosition rectangelWithoutId.startingTime rectangelWithoutId.duration


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
                clearLevel (List.length(model.boxes)) model   
            else
                ( {model | boxes = List.map updateZappedElement model.boxes}, Cmd.none )
        GenerateRandomRectangles rectangles ->
            ({model | boxes = rectangles}, Cmd.none)
        EndLevel ->
            clearLevel (List.length(model.boxes)) model
        Tick newTime ->
            ( { model | timer = model.timer + 1 }, Cmd.none)


clearLevel : Int -> Model -> (Model, Cmd Msg)
clearLevel endingNumber model = ({model | boxes = [], level = model.level + 1}, Random.generate GenerateRandomRectangles (initialRectangles endingNumber)) 
---- VIEW ----

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
        encompassedRectangle smartRectangle.xPosition smartRectangle.startingTime smartRectangle.id smartRectangle.duration model.level
    else
        Svg.text ""

rectangleWidth : Int
rectangleWidth  = 100

rectangleHeight : Int
rectangleHeight = 100

startingBoxPosition : Int
startingBoxPosition = 0 - rectangleHeight

encompassedRectangle : Int -> Int -> Int -> Int -> Int -> Svg Msg
encompassedRectangle xPosition startingTime id duration level =
    let     
        
            animationFactor = if (level == 1) then
                                    animate [ from (String.fromInt startingBoxPosition), to "800", begin (String.fromInt( startingTime )), dur ((String.fromInt duration) ++ "s"), repeatCount "1", attributeName "y"] []    
                              else
                                    animate [ from (String.fromInt startingBoxPosition), to "800", begin (String.fromInt( startingTime + level * 10)), dur ((String.fromInt duration) ++ "s"), repeatCount "1", attributeName "y"] []    
    in  
        rect
                [ width (String.fromInt rectangleWidth)
                , height (String.fromInt rectangleHeight)
                , fill "dodgerblue"
                , onClick (Zap id)
                , x (String.fromInt xPosition)
                , y (String.fromInt startingBoxPosition)
                , rx "15", ry "15"
                ]
                [ animationFactor
                ]        

maxDurationOfLevel : Int
maxDurationOfLevel = 10000

---- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Time.every 1000 Tick 

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
    }
