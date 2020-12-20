{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- | HTML & CSS
module Neuron.Web.View where

import Clay (Css, em, gray, important, pct, (?))
import qualified Clay as C
import Control.Monad.Fix (MonadFix)
import Neuron.Config.Type (Config (..))
import Neuron.Web.Common (neuronCommonStyle, neuronFonts)
import qualified Neuron.Web.Impulse as Impulse
import qualified Neuron.Web.Query.View as QueryView
import Neuron.Web.Route
  ( NeuronWebT,
    Route (..),
    routeTitle',
  )
import qualified Neuron.Web.Theme as Theme
import Neuron.Web.Widget (elLinkGoogleFonts)
import qualified Neuron.Web.Zettel.CSS as ZettelCSS
import qualified Neuron.Web.Zettel.View as ZettelView
import Neuron.Zettelkasten.Graph (ZettelGraph)
import Reflex.Dom.Core
import Reflex.Dom.Pandoc (PandocBuilder)
import Relude

headTemplate ::
  DomBuilder t m =>
  m () ->
  m ()
headTemplate titleWidget = do
  elAttr "meta" ("http-equiv" =: "Content-Type" <> "content" =: "text/html; charset=utf-8") blank
  elAttr "meta" ("name" =: "viewport" <> "content" =: "width=device-width, initial-scale=1") blank
  el "title" titleWidget
  elAttr "link" ("rel" =: "stylesheet" <> "href" =: "https://cdn.jsdelivr.net/npm/fomantic-ui@2.8.7/dist/semantic.min.css") blank
  elAttr "style" ("type" =: "text/css") $ text $ toText $ C.renderWith C.compact [] style
  elLinkGoogleFonts neuronFonts

routeTitle :: Config -> a -> Route a -> Text
routeTitle Config {..} v =
  withSuffix siteTitle . routeTitle' v
  where
    withSuffix suffix x =
      if x == suffix
        then x
        else x <> " - " <> suffix

bodyTemplate ::
  forall t m.
  DomBuilder t m =>
  Text ->
  Config ->
  m () ->
  m ()
bodyTemplate neuronVersion Config {..} w = do
  let neuronTheme = Theme.mkTheme theme
      themeSelector = toText $ Theme.themeIdentifier neuronTheme
  elAttr "div" ("class" =: "ui fluid container universe" <> "id" =: themeSelector) $ do
    w
    renderBrandFooter neuronVersion

-- TODO: Deconstruct and move to Main.hs, because the Route_Impulse stuff need
-- not be in library.
renderRouteBody ::
  forall t m a.
  (PandocBuilder t m, PostBuild t m, MonadHold t m, MonadFix m) =>
  Text ->
  Config ->
  Route a ->
  (ZettelGraph, a) ->
  NeuronWebT t m ()
renderRouteBody neuronVersion cfg@Config {..} r (g, val) =
  case r of
    Route_Impulse {} -> do
      -- HTML for this route is all handled in JavaScript (compiled from
      -- impulse's sources).
      let (_cache, js) = val
      -- XXX: Disabling JSON cache, because we don't yet know of a performant
      -- way to load it in GHCJS.
      -- ...
      -- The JSON cache being injected here will be accessed at runtime by
      -- Impulse. It is also available on disk as `cache.json`, which Impulse
      -- retrieves in development mode (as no injection can happen in the
      -- GHC/jsaddle context).
      {-
      let cacheJsonJson =
            TL.toStrict $
              encodeToLazyText $
                TL.toStrict $ encodeToLazyText cache
      el "script" $ text $ "\nvar cacheText = " <> cacheJsonJson <> ";\n"
      -- el "script" $ text $ "\nvar cache = " <> (TL.toStrict . encodeToLazyText) cache <> ";\n"
      -}
      el "script" $ text js
    Route_Zettel _ -> do
      bodyTemplate neuronVersion cfg $ do
        let neuronTheme = Theme.mkTheme theme
        ZettelView.renderZettel neuronTheme (g, val) editUrl

renderBrandFooter :: DomBuilder t m => Text -> m ()
renderBrandFooter ver =
  divClass "ui center aligned container footer-version" $ do
    divClass "ui tiny image" $ do
      elAttr "a" ("href" =: "https://neuron.zettel.page") $ do
        elAttr
          "img"
          ( "src" =: "https://raw.githubusercontent.com/srid/neuron/master/assets/neuron.svg"
              <> "alt" =: "logo"
              <> "title" =: ("Generated by Neuron (" <> ver <> ")")
          )
          blank

style :: Css
style = do
  "body" ? do
    neuronCommonStyle
    Impulse.style
    ZettelCSS.zettelCss
    QueryView.style
    footerStyle
  where
    footerStyle = do
      ".footer-version img" ? do
        C.filter $ C.grayscale $ pct 100
      ".footer-version img:hover" ? do
        C.filter $ C.grayscale $ pct 0
      ".footer-version, .footer-version a, .footer-version a:visited" ? do
        C.color gray
      ".footer-version a" ? do
        C.fontWeight C.bold
      ".footer-version" ? do
        important $ C.marginTop $ em 1
        C.fontSize $ em 0.7
