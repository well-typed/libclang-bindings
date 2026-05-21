{-# LANGUAGE CPP #-}
module Clang.Internal.Exception (
    ExactException(..)
  , throwExact
  , RunInIO
  , HandlerResult(..)
  , handleUnliftUsing
  ) where

import Control.Exception (Exception (..))
import Control.Exception qualified as Base
import Control.Monad.IO.Class (MonadIO (..))

{-------------------------------------------------------------------------------
  Internal: exception handling
-------------------------------------------------------------------------------}

-- | Newtype wrapper for throwing this /exact/ exception
--
-- In other words, including any exception annotations.
newtype ExactException = WrapExactException {
      unwrapExactException :: Base.SomeException
    }
  deriving stock (Show)

instance Exception ExactException where
  fromException    = Just . WrapExactException
  toException      = unwrapExactException
  displayException = displayException . unwrapExactException
#if MIN_VERSION_base(4,20,0)
  backtraceDesired = const False
#endif

-- | Type-specialized wrapper around throwIO, to avoid mistakes
--
-- Implementation note: does not need a 'HasCallStack' constraint, because
-- no new backtrace is added.
throwExact :: ExactException -> IO a
throwExact = Base.throwIO

type RunInIO m = forall a. m a -> IO a

-- | Exception handler result
--
-- This generalizes two functions:
--
-- * 'handle' through 'HandlerResult'
-- * 'onException' through 'HandlerRethrow'
--
-- See 'handleUnliftUsing'.
data HandlerResult a =
    -- | Handler dealt with the exception and computed a new result
    HandlerResult a

    -- | Handler dealt with the exception, perhaps freeing some resources,
    -- and wants to rethrow the original exception.
    --
    -- This mimicks the behaviour of 'onException'.
  | HandlerRethrow
  deriving stock (Show, Functor)

-- | Generalized 'handle'
--
-- If the exception handler throws an exception of its own, instead of returning
-- a result, a 'WhileHandling' annotation is added to that exception recording
-- the original exception that was being handled (in GHC >= 9.12).
--
-- Implementation note: We do not use @handle@ from @unlift@, as it excludes
-- async exceptions, and we want it to be up to the exception handler to decide
-- if it wants to deal with async exceptions or not.
handleUnliftUsing ::
     MonadIO n
  => RunInIO m
  -> (ExactException -> m (HandlerResult a))
  -> m a -> n a
handleUnliftUsing runInIO handler action = liftIO $
        Base.handle
          (\e -> Left . (e,) <$> runInIO (handler e))
          (Right <$> runInIO action)
    >>= aux
  where
    aux :: Either (ExactException, HandlerResult a) a -> IO a
    aux = \case
        Right a -> return a
        Left (e, handlerResult) ->
          case handlerResult of
            HandlerResult a -> return a
            HandlerRethrow  -> throwExact e

