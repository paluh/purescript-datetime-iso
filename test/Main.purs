module Test.Main where

import Prelude

import Control.Monad.Error.Class (class MonadThrow)
import Data.Argonaut.Core (fromString)
import Data.Argonaut.Decode (decodeJson)
import Data.DateTime as DT
import Data.DateTime.ISO (ISO(..))
import Data.Either (Either(..))
import Data.Enum (class BoundedEnum, toEnum)
import Data.Maybe (fromJust)
import Effect (Effect)
import Effect.Aff (Error, launchAff_)
import Partial.Unsafe (unsafePartial)
import Test.Spec (describe, it)
import Test.Spec.Assertions (expectError, shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)

main :: Effect Unit
main = launchAff_ $ runSpec [ consoleReporter ] do
  describe "purescript-datetime-iso" do

    describe "decoding" do

      it "decodes standard js ISO strings (ala Date.prototype.toISOString)" do
        checkRoundtrip "2018-01-09T13:16:43.772Z" "2018-01-09T13:16:43.772Z"

      describe "optional characters" do
        it "doesn't need hyphens in the date" do
          checkRoundtrip "20180109T13:16:43.772Z" "2018-01-09T13:16:43.772Z"

        it "doesn't need colons in the time" do
          checkRoundtrip "20180109T131643.772Z" "2018-01-09T13:16:43.772Z"

      describe "milliseconds" do

        it "handles zero milliseconds" do
          checkRoundtrip "2018-01-09T13:16:43.0Z" "2018-01-09T13:16:43.0Z"

        it "handles empty milliseconds" do
          checkRoundtrip "2018-01-09T13:16:43Z" "2018-01-09T13:16:43.0Z"

        it "handles milliseconds 0-999" do
          checkRoundtrip "2018-01-09T13:16:43.999Z" "2018-01-09T13:16:43.999Z"

        it "handles more than 3 digits second fraction" do
          checkRoundtrip "2018-01-09T13:16:43.1234Z" "2018-01-09T13:16:43.123Z"

        it "handles milliseconds with one leading zero" do
          checkRoundtrip "2018-01-09T03:16:43.034Z" "2018-01-09T03:16:43.034Z"

        it "handles milliseconds with two leading zeros" do
          checkRoundtrip "2018-01-09T13:06:33.002Z" "2018-01-09T13:06:33.002Z"

        it "handles two digit milliseconds with leading zero" do
          checkRoundtrip "2018-01-09T13:26:03.07Z" "2018-01-09T13:26:03.07Z"

        it "handles two digit milliseconds with leading and trailing zero" do
          checkRoundtrip "2018-01-09T13:06:03.070Z" "2018-01-09T13:06:03.07Z"

      describe "malformed input" do -- malformed as far as we're concerned...

        it "fails if not YYYY MM DD" do
          expectError $ checkRoundtrip "2018-1-9T13:16:43.1Z" "2018-1-9T13:16:43.1Z"

        it "requires a terminating 'Z' (UTC)" do
          expectError $ checkRoundtrip "2018-1-9T13:16:43.0" "2018-1-9T13:16:43.1Z"

    describe "printing" do

      it "prints like an ISO string" do
        let dt = mkDateTime 2018 DT.January 9 13 16 43 772
        show (ISO dt) `shouldEqual` "2018-01-09T13:16:43.772Z"

      it "explicitly prints zero milliseconds" do
        let dt = mkDateTime 2018 DT.January 9 13 16 43 0
        show (ISO dt) `shouldEqual` "2018-01-09T13:16:43.0Z"

      it "prints milliseconds with two leading zeros" do
        let dt = mkDateTime 2018 DT.January 9 13 16 43 3
        show (ISO dt) `shouldEqual` "2018-01-09T13:16:43.003Z"

      it "prints milliseconds with one leading zero" do
        let dt = mkDateTime 2018 DT.January 9 13 16 43 40
        show (ISO dt) `shouldEqual` "2018-01-09T13:16:43.04Z"

      it "removes unneeded zeros from end of milliseconds" do
        let dt = mkDateTime 2018 DT.January 9 13 16 43 840
        show (ISO dt) `shouldEqual` "2018-01-09T13:16:43.84Z"

checkRoundtrip :: forall m. MonadThrow Error m => String -> String -> m Unit
checkRoundtrip value expected =
  (map show $ (decodeJson $ fromString value :: _ _ ISO)) `shouldEqual` Right expected

-- Helper function for constructing DateTimes.
mkDateTime
  :: Int
  -> DT.Month
  -> Int
  -> Int
  -> Int
  -> Int
  -> Int
  -> DT.DateTime
mkDateTime year month day hh mm ss ms =
  let
    date =
      DT.canonicalDate
        (toEnum' year)
        month
        (toEnum' day)
    time =
      DT.Time
        (toEnum' hh)
        (toEnum' mm)
        (toEnum' ss)
        (toEnum' ms)
  in
    DT.DateTime date time
  where
  toEnum' :: forall a. BoundedEnum a => Int -> a
  toEnum' = toEnum >>> unsafePartial fromJust
