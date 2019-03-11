{$DEFINE VCL_TARGET}

//############################################################################
// All delphi versions support Win32, so this we can define
// without much reservation
//############################################################################

{$DEFINE SUPPORT_WIN32}

//############################################################################
// Conditional expressions was introduced in Delphi 6.
// If this is not present, we know we are dealing with a very old version.
// How much will actually compile is unknown since the oldest Delphi I have
// is version 7. But classical object pascal never really changed that much
//############################################################################

{$IFNDEF CONDITIONALEXPRESSIONS}
  {$IFDEF VER80}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
    {$DEFINE NO_UINT64}
  {$ENDIF}

  {$IFDEF VER90}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
    {$DEFINE NO_UINT64}
  {$ENDIF}

  {$IFDEF VER100}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
    {$DEFINE NO_UINT64}
  {$ENDIF}

  {$IFDEF VER120}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
    {$DEFINE NO_UINT64}
  {$ENDIF}

  {$IFDEF VER130}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

  {$IFDEF VER140}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

  {$IFDEF VER150}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

  {$IFDEF VER160}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

  {$IFDEF VER170}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

  // Delphi 2006 [and codegear 2007]
  {$IFDEF VER180}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

  // Delphi 2007
  {$IFDEF VER185}
    {$IFOPT D+}
      {$DEFINE DEBUG}
    {$ENDIF}
    {$DEFINE DELPHI_CLASSIC}
    {$DEFINE PATCH_NATIVE_INT}
  {$ENDIF}

{$ENDIF}

//############################################################################
// Now go through the modern versions
// Anything before XE is vanilla stuff anyways
//############################################################################

// Delphi XE
{$IF CompilerVersion = 22	}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE DELPHI_XE}
{$ENDIF}

// Delphi XE2
{$IF CompilerVersion = 23}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOSDevice}
{$ENDIF}

// Delphi XE3
{$IF CompilerVersion = 24}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOSDevice}
{$ENDIF}

// Delphi XE4
{$IF CompilerVersion = 25}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOSDevice}
{$ENDIF}

// Delphi XE5
{$IF CompilerVersion = 26}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOSDevice}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

// Delphi XE6
{$IF CompilerVersion = 27}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOSDevice}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}


// Delphi XE7
{$IF CompilerVersion = 28}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOS32}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

// Delphi XE8
{$IF CompilerVersion = 29}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOS32}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

// Delphi XE10 Seattle
{$IF CompilerVersion = 30}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOS32}
  {$DEFINE SUPPORT_IOS64}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

// Delphi XE10 Berlin
{$IF CompilerVersion = 31}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_IOS32}
  {$DEFINE SUPPORT_IOS64}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

// Delphi XE10 Tokyo
{$IF CompilerVersion = 32}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_OSX64}
  {$DEFINE SUPPORT_IOS32}
  {$DEFINE SUPPORT_IOS64}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

// Delphi XE10 RIO and beyond
{$IF CompilerVersion >= 33}
  {$DEFINE USE_NEW_UNITNAMES}
  {$DEFINE SUPPORT_STRICT}
  {$DEFINE SUPPORT_PIDS}
  {$DEFINE SUPPORT_SEALED}
  {$DEFINE SUPPORT_WIN32}
  {$DEFINE SUPPORT_WIN64}
  {$DEFINE SUPPORT_OSX32}
  {$DEFINE SUPPORT_OSX64}
  {$DEFINE SUPPORT_IOS32}
  {$DEFINE SUPPORT_IOS64}
  {$DEFINE SUPPORT_ANDROID}
{$ENDIF}

{$IFNDEF DEBUG}
  {$DebugInfo       OFF}
  {$TYPEINFO        OFF}
  {$DefinitionInfo  OFF}
  {$LocalSymbols    OFF}
  {$ReferenceInfo   OFF}
{$ENDIF}
{$WARN SYMBOL_PLATFORM OFF}



