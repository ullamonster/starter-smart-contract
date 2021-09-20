{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE NoImplicitPrelude    #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TemplateHaskell      #-}
{-# LANGUAGE TypeApplications     #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE TypeOperators        #-}

module simpleSale where

import            Control.Monad       hiding (fmap)
import            Data.map            as Map
import            Data.Text           (Text)
import            Data.Void           (Void)
import            Plutus.Contract
import            PlutusTx            (Data (..))
import  qualified PlutusTx
import            PlutusTx.Prelude    hiding (Semigroup(..), unless)
import            Ledger              hiding (singleton)
import            Ledger.Constraints  as Constraints
import  qualified Ledger.Scripts      as Scripts
import            Ledger.Ada          as Ada
import            Text.Printf         (printf)

{-# OPTIONS_GHC -fno-warn-unused-imports #-}

-- Create the validator, as inlinable
{-# INLINABLE saleValidator #-}
saleValidator :: () -> Integer -> ScriptContext -> Bool
saleValidator _ r _ = traceIfFalse "Incorrect Redeemer!" $ r == 27
-- Following would return no "nice" error, new above using traceIfFalse
-- saleValidator _ r _ = r == 27
  -- Redeemer must match the integer 27 or fails .. new code above ^
  -- | r == I 27 = ()
  -- | otherwise = traceError "Incorrect Redeemer!"

-- ## Boilerplate for compiling a typed validator ##
-- Define dummy data types
data saleDataType
instance Scripts.ValidatorTypes saleDataType where
  type instance DatumType saleDataType = ()
  type instance RedeemerType saleDataType = Integer
  
-- Wrap the validator with types and compiler (make typed validator vs make validator)
saledatatypeValidator :: Scripts.TypedValidator saleDataType
saledatatypeValidator = Scripts.mkTypedValidator @saleDataType
    $$(PlutusTx.compile [|| saleValidator ||])
    $$(PlutusTx.compile [|| wrap ||])
  where
    wrap = Scripts.wrapValidator @() @Integer

-- Compile the validator to plutus core
validator :: Validator
validator = Scripts.validatorScript saledatatypeValidator
-- ## End of Boilerplate ##

-- Get the hash of the validator
valHash :: Ledger.ValidatorHash
-- Updated for using the above boilerplate:
valHash = Scripts.validatorHash saledatatypeValidator

-- Get the address of the validator
srcAddress :: Ledger.Address
srcAddress = scriptAddress validator

