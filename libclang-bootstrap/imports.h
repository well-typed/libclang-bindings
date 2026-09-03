// *** Top-level ***
// <https://clang.llvm.org/doxygen/group__CINDEX.html>

CXIndex             clang_createIndex (int excludeDeclarationsFromPCH, int displayDiagnostics);
void                clang_disposeIndex (CXIndex index);
// OMITTED: CXIndex             clang_createIndexWithOptions (const CXIndexOptions * options);
// OMITTED: void                clang_CXIndex_setGlobalOptions (CXIndex, unsigned options);
// OMITTED: unsigned            clang_CXIndex_getGlobalOptions (CXIndex);
// OMITTED: void                clang_CXIndex_setInvocationEmissionPathOption (CXIndex, const char * Path);
// OMITTED: unsigned            clang_isFileMultipleIncludeGuarded (CXTranslationUnit tu, CXFile file);
CXFile              clang_getFile (CXTranslationUnit tu, const char * file_name);
const char *        clang_getFileContents (CXTranslationUnit tu, CXFile file, size_t * size);
CXSourceLocation    clang_getLocation (CXTranslationUnit tu, CXFile file, unsigned line, unsigned column);
// OMITTED: CXSourceLocation    clang_getLocationForOffset (CXTranslationUnit tu, CXFile file, unsigned offset);
// OMITTED: CXSourceRangeList * clang_getSkippedRanges (CXTranslationUnit tu, CXFile file);
// OMITTED: CXSourceRangeList * clang_getAllSkippedRanges (CXTranslationUnit tu);
unsigned            clang_getNumDiagnostics (CXTranslationUnit Unit);
CXDiagnostic        clang_getDiagnostic (CXTranslationUnit Unit, unsigned Index);
// OMITTED: CXDiagnosticSet     clang_getDiagnosticSetFromTU (CXTranslationUnit Unit);

// *** Diagnostic reporting ***
// <https://clang.llvm.org/doxygen/group__CINDEX__DIAG.html>

unsigned                  clang_getNumDiagnosticsInSet (CXDiagnosticSet Diags);
CXDiagnostic              clang_getDiagnosticInSet (CXDiagnosticSet Diags, unsigned Index);
// OMITTED: CXDiagnosticSet           clang_loadDiagnostics (const char * file, enum CXLoadDiag_Error * error, CXString * errorString);
void                      clang_disposeDiagnosticSet (CXDiagnosticSet Diags);
CXDiagnosticSet           clang_getChildDiagnostics (CXDiagnostic D);
void                      clang_disposeDiagnostic (CXDiagnostic Diagnostic);
CXString                  clang_formatDiagnostic (CXDiagnostic Diagnostic, unsigned Options);
unsigned                  clang_defaultDiagnosticDisplayOptions (void);
enum CXDiagnosticSeverity clang_getDiagnosticSeverity (CXDiagnostic Diag);
CXSourceLocation          clang_getDiagnosticLocation (CXDiagnostic Diag);
CXString                  clang_getDiagnosticSpelling (CXDiagnostic Diag);
CXString                  clang_getDiagnosticOption (CXDiagnostic Diag, CXString * Disable);
unsigned                  clang_getDiagnosticCategory (CXDiagnostic Diag);
CXString                  clang_getDiagnosticCategoryText (CXDiagnostic Diag);
unsigned                  clang_getDiagnosticNumRanges (CXDiagnostic Diag);
CXSourceRange             clang_getDiagnosticRange (CXDiagnostic Diagnostic, unsigned Range);
unsigned                  clang_getDiagnosticNumFixIts (CXDiagnostic Diagnostic);
CXString                  clang_getDiagnosticFixIt (CXDiagnostic Diagnostic, unsigned FixIt, CXSourceRange * ReplacementRange);

// *** File manipulation routines ***
// <https://clang.llvm.org/doxygen/group__CINDEX__FILES.html>

CXString clang_getFileName (CXFile SFile);
// OMITTED: time_t   clang_getFileTime (CXFile SFile);
// OMITTED: int      clang_getFileUniqueID (CXFile file, CXFileUniqueID * outID);
// OMITTED: int      clang_File_isEqual (CXFile file1, CXFile file2);
CXString clang_File_tryGetRealPathName (CXFile file);

// *** Physical source locations ***
// <https://clang.llvm.org/doxygen/group__CINDEX__LOCATIONS.html>

// OMITTED: CXSourceLocation clang_getNullLocation (void);
// OMITTED: unsigned         clang_equalLocations (CXSourceLocation loc1, CXSourceLocation loc2);

#ifdef HAVE_CLANG_ISBEFOREINTRANSLATIONUNIT
unsigned         clang_isBeforeInTranslationUnit (CXSourceLocation loc1, CXSourceLocation loc2);
#endif

// OMITTED: int              clang_Location_isInSystemHeader (CXSourceLocation location);
int              clang_Location_isFromMainFile (CXSourceLocation location);
// OMITTED: CXSourceRange    clang_getNullRange (void);
CXSourceRange    clang_getRange (CXSourceLocation begin, CXSourceLocation end);
// OMITTED: unsigned         clang_equalRanges (CXSourceRange range1, CXSourceRange range2);
int              clang_Range_isNull (CXSourceRange range);
void             clang_getExpansionLocation (CXSourceLocation location, CXFile * file, unsigned * line, unsigned * column, unsigned * offset);
void             clang_getPresumedLocation (CXSourceLocation location, CXString * filename, unsigned * line, unsigned * column);
// OMITTED: void             clang_getInstantiationLocation (CXSourceLocation location, CXFile * file, unsigned * line, unsigned * column, unsigned * offset);
void             clang_getSpellingLocation (CXSourceLocation location, CXFile * file, unsigned * line, unsigned * column, unsigned * offset);
void             clang_getFileLocation (CXSourceLocation location, CXFile * file, unsigned * line, unsigned * column, unsigned * offset);
CXSourceLocation clang_getRangeStart (CXSourceRange range);
CXSourceLocation clang_getRangeEnd (CXSourceRange range);
// OMITTED: void             clang_disposeSourceRangeList (CXSourceRangeList * ranges);

// *** String manipulation routines ***
// <https://clang.llvm.org/doxygen/group__CINDEX__STRING.html>

const char * clang_getCString (CXString string);
void         clang_disposeString (CXString string);
// OMITTED: void         clang_disposeStringSet (CXStringSet * set);

// *** Translation unit manipulation ***
// <https://clang.llvm.org/doxygen/group__CINDEX__TRANSLATION__UNIT.html>

// OMITTED: CXString          clang_getTranslationUnitSpelling (CXTranslationUnit CTUnit);
// OMITTED: CXTranslationUnit clang_createTranslationUnitFromSourceFile (CXIndex CIdx, const char * source_filename, int num_clang_command_line_args, const char * const * clang_command_line_args, unsigned num_unsaved_files, struct CXUnsavedFile * unsaved_files);
// OMITTED: CXTranslationUnit clang_createTranslationUnit (CXIndex CIdx, const char * ast_filename);
// OMITTED: enum CXErrorCode  clang_createTranslationUnit2 (CXIndex CIdx, const char * ast_filename, CXTranslationUnit * out_TU);
// OMITTED: unsigned          clang_defaultEditingTranslationUnitOptions (void);
CXTranslationUnit clang_parseTranslationUnit (CXIndex CIdx, const char * source_filename, const char * const * command_line_args, int num_command_line_args, struct CXUnsavedFile * unsaved_files, unsigned num_unsaved_files, unsigned options);
enum CXErrorCode  clang_parseTranslationUnit2 (CXIndex CIdx, const char * source_filename, const char * const * command_line_args, int num_command_line_args, struct CXUnsavedFile * unsaved_files, unsigned num_unsaved_files, unsigned options, CXTranslationUnit * out_TU);
// OMITTED: enum CXErrorCode  clang_parseTranslationUnit2FullArgv (CXIndex CIdx, const char * source_filename, const char * const * command_line_args, int num_command_line_args, struct CXUnsavedFile * unsaved_files, unsigned num_unsaved_files, unsigned options, CXTranslationUnit * out_TU);
// OMITTED: unsigned          clang_defaultSaveOptions (CXTranslationUnit TU);
// OMITTED: int               clang_saveTranslationUnit (CXTranslationUnit TU, const char * FileName, unsigned options);
// OMITTED: unsigned          clang_suspendTranslationUnit (CXTranslationUnit TU);
void              clang_disposeTranslationUnit (CXTranslationUnit TU);
// OMITTED: unsigned          clang_defaultReparseOptions (CXTranslationUnit TU);
// OMITTED: int               clang_reparseTranslationUnit (CXTranslationUnit TU, unsigned num_unsaved_files, struct CXUnsavedFile * unsaved_files, unsigned options);
// OMITTED: const char *      clang_getTUResourceUsageName (enum CXTUResourceUsageKind kind);
// OMITTED: CXTUResourceUsage clang_getCXTUResourceUsage (CXTranslationUnit TU);
// OMITTED: void              clang_disposeCXTUResourceUsage (CXTUResourceUsage usage);
CXTargetInfo      clang_getTranslationUnitTargetInfo (CXTranslationUnit CTUnit);
void              clang_TargetInfo_dispose (CXTargetInfo Info);
CXString          clang_TargetInfo_getTriple (CXTargetInfo Info);
// OMITTED: int               clang_TargetInfo_getPointerWidth (CXTargetInfo Info);

// *** Cursor manipulations ***
// <https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__MANIP.html>

CXCursor                clang_getNullCursor (void);
CXCursor                clang_getTranslationUnitCursor (CXTranslationUnit TU);
unsigned                clang_equalCursors (CXCursor C1, CXCursor C2);
int                     clang_Cursor_isNull (CXCursor C);
unsigned                clang_hashCursor (CXCursor C);
enum CXCursorKind       clang_getCursorKind (CXCursor C);
unsigned                clang_isDeclaration (enum CXCursorKind CK);
unsigned                clang_isInvalidDeclaration (CXCursor C);
unsigned                clang_isReference (enum CXCursorKind CK);
unsigned                clang_isExpression (enum CXCursorKind CK);
unsigned                clang_isStatement (enum CXCursorKind CK);
unsigned                clang_isAttribute (enum CXCursorKind CK);
unsigned                clang_Cursor_hasAttrs (CXCursor C);
unsigned                clang_isInvalid (enum CXCursorKind CK);
unsigned                clang_isTranslationUnit (enum CXCursorKind CK);
unsigned                clang_isPreprocessing (enum CXCursorKind CK);
unsigned                clang_isUnexposed (enum CXCursorKind CK);
enum CXLinkageKind      clang_getCursorLinkage (CXCursor cursor);
enum CXVisibilityKind   clang_getCursorVisibility (CXCursor cursor);
enum CXAvailabilityKind clang_getCursorAvailability (CXCursor cursor);
// OMITTED: int                     clang_getCursorPlatformAvailability (CXCursor cursor, int * always_deprecated, CXString * deprecated_message, int * always_unavailable, CXString * unavailable_message, CXPlatformAvailability * availability, int availability_size);
// OMITTED: void                    clang_disposeCXPlatformAvailability (CXPlatformAvailability * availability);
CXCursor                clang_Cursor_getVarDeclInitializer (CXCursor cursor);
int                     clang_Cursor_hasVarDeclGlobalStorage (CXCursor cursor);
int                     clang_Cursor_hasVarDeclExternalStorage (CXCursor cursor);
// OMITTED: enum CXLanguageKind     clang_getCursorLanguage (CXCursor cursor);
enum CXTLSKind          clang_getCursorTLSKind (CXCursor cursor);
CXTranslationUnit       clang_Cursor_getTranslationUnit (CXCursor cursor);
// OMITTED: CXCursorSet             clang_createCXCursorSet (void);
// OMITTED: void                    clang_disposeCXCursorSet (CXCursorSet cset);
// OMITTED: unsigned                clang_CXCursorSet_contains (CXCursorSet cset, CXCursor cursor);
// OMITTED: unsigned                clang_CXCursorSet_insert (CXCursorSet cset, CXCursor cursor);
CXCursor                clang_getCursorSemanticParent (CXCursor cursor);
CXCursor                clang_getCursorLexicalParent (CXCursor cursor);
// OMITTED: void                    clang_getOverriddenCursors (CXCursor cursor, CXCursor * * overridden, unsigned * num_overridden);
// OMITTED: void                    clang_disposeOverriddenCursors (CXCursor * overridden);
CXFile                  clang_getIncludedFile (CXCursor cursor);

// *** Mapping between cursors and source code  ***
// <https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__SOURCE.html>

// OMITTED: CXCursor         clang_getCursor (CXTranslationUnit TU, CXSourceLocation Source);
CXSourceLocation clang_getCursorLocation (CXCursor cursor);
CXSourceRange    clang_getCursorExtent (CXCursor cursor);

// *** Type information for CXCursors ***
// <https://clang.llvm.org/doxygen/group__CINDEX__TYPES.html>

CXType                      clang_getCursorType (CXCursor C);
CXString                    clang_getTypeSpelling (CXType CT);
CXType                      clang_getTypedefDeclUnderlyingType (CXCursor C);
CXType                      clang_getEnumDeclIntegerType (CXCursor C);
long long                   clang_getEnumConstantDeclValue (CXCursor C);
unsigned long long          clang_getEnumConstantDeclUnsignedValue (CXCursor C);
unsigned                    clang_Cursor_isBitField (CXCursor C);
int                         clang_getFieldDeclBitWidth (CXCursor C);
int                         clang_Cursor_getNumArguments (CXCursor C);
CXCursor                    clang_Cursor_getArgument (CXCursor C, unsigned i);
// OMITTED: int                         clang_Cursor_getNumTemplateArguments (CXCursor C);
// OMITTED: enum CXTemplateArgumentKind clang_Cursor_getTemplateArgumentKind (CXCursor C, unsigned I);
// OMITTED: CXType                      clang_Cursor_getTemplateArgumentType (CXCursor C, unsigned I);
// OMITTED: long long                   clang_Cursor_getTemplateArgumentValue (CXCursor C, unsigned I);
// OMITTED: unsigned long long          clang_Cursor_getTemplateArgumentUnsignedValue (CXCursor C, unsigned I);
unsigned                    clang_equalTypes (CXType A, CXType B);
CXType                      clang_getCanonicalType (CXType T);
unsigned                    clang_isConstQualifiedType (CXType T);
unsigned                    clang_Cursor_isMacroFunctionLike (CXCursor C);
unsigned                    clang_Cursor_isMacroBuiltin (CXCursor C);
unsigned                    clang_Cursor_isFunctionInlined (CXCursor C);
unsigned                    clang_isVolatileQualifiedType (CXType T);
unsigned                    clang_isRestrictQualifiedType (CXType T);
unsigned                    clang_getAddressSpace (CXType T);
CXString                    clang_getTypedefName (CXType CT);
CXType                      clang_getPointeeType (CXType T);
// OMITTED: CXType                      clang_getUnqualifiedType (CXType CT); // NOTE: does not exist before clang-16, so we define a custom wrapper in clang_wrappers.h
// OMITTED: CXType                      clang_getNonReferenceType (CXType CT);
CXCursor                    clang_getTypeDeclaration (CXType T);
// OMITTED: CXString                    clang_getDeclObjCTypeEncoding (CXCursor C);
// OMITTED: CXString                    clang_Type_getObjCEncoding (CXType type);
CXString                    clang_getTypeKindSpelling (enum CXTypeKind K);
// OMITTED: enum CXCallingConv          clang_getFunctionTypeCallingConv (CXType T);
CXType                      clang_getResultType (CXType T);
// OMITTED: int                         clang_getExceptionSpecificationType (CXType T);
int                         clang_getNumArgTypes (CXType T);
CXType                      clang_getArgType (CXType T, unsigned i);
CXType                      clang_Type_getObjCObjectBaseType (CXType T);
unsigned                    clang_Type_getNumObjCProtocolRefs (CXType T);
CXCursor                    clang_Type_getObjCProtocolDecl (CXType T, unsigned i);
unsigned                    clang_Type_getNumObjCTypeArgs (CXType T);
CXType                      clang_Type_getObjCTypeArg (CXType T, unsigned i);
unsigned                    clang_isFunctionTypeVariadic (CXType T);
CXType                      clang_getCursorResultType (CXCursor C);
int                         clang_getCursorExceptionSpecificationType (CXCursor C);
unsigned                    clang_isPODType (CXType T);
CXType                      clang_getElementType (CXType T);
long long                   clang_getNumElements (CXType T);
CXType                      clang_getArrayElementType (CXType T);
long long                   clang_getArraySize (CXType T);
CXType                      clang_Type_getNamedType (CXType T);
unsigned                    clang_Type_isTransparentTagTypedef (CXType T);
// OMITTED: enum CXTypeNullabilityKind  clang_Type_getNullability (CXType T);
long long                   clang_Type_getAlignOf (CXType T);
// OMITTED: CXType                      clang_Type_getClassType (CXType T);
long long                   clang_Type_getSizeOf (CXType T);
long long                   clang_Type_getOffsetOf (CXType T, const char * S);
CXType                      clang_Type_getModifiedType (CXType T);
CXType                      clang_Type_getValueType (CXType CT);
long long                   clang_Cursor_getOffsetOfField (CXCursor C);
unsigned                    clang_Cursor_isAnonymous (CXCursor C);
unsigned                    clang_Cursor_isAnonymousRecordDecl (CXCursor C);
// OMITTED: unsigned                    clang_Cursor_isInlineNamespace (CXCursor C);
// OMITTED: int                         clang_Type_getNumTemplateArguments (CXType T);
// OMITTED: CXType                      clang_Type_getTemplateArgumentAsType (CXType T, unsigned i);
// OMITTED: enum CXRefQualifierKind     clang_Type_getCXXRefQualifier (CXType T);
// OMITTED: unsigned                    clang_isVirtualBase (CXCursor C);
// OMITTED: long long                   clang_getOffsetOfBase (CXCursor Parent, CXCursor Base);
// OMITTED: enum CX_CXXAccessSpecifier  clang_getCXXAccessSpecifier (CXCursor C);
// OMITTED: enum CX_BinaryOperatorKind  clang_Cursor_getBinaryOpcode (CXCursor C);
// OMITTED: CXString                    clang_Cursor_getBinaryOpcodeStr (enum CX_BinaryOperatorKind Op);
enum CX_StorageClass        clang_Cursor_getStorageClass (CXCursor C);
// OMITTED: unsigned                    clang_getNumOverloadedDecls (CXCursor cursor);
// OMITTED: CXCursor                    clang_getOverloadedDecl (CXCursor cursor, unsigned index);

// *** Traversing the AST with cursors ***
// <https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__TRAVERSAL.html>

// OMITTED: unsigned clang_visitChildren (CXCursor parent, CXCursorVisitor visitor, CXClientData client_data);
// OMITTED: unsigned clang_visitChildrenWithBlock (CXCursor parent, CXCursorVisitorBlock block);

// *** Cross-referencing in the AST  ***
// <https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__XREF.html>

// OMITTED: CXString         clang_getCursorUSR (CXCursor);
// OMITTED: CXString         clang_constructUSR_ObjCClass (const char * class_name);
// OMITTED: CXString         clang_constructUSR_ObjCCategory (const char * class_name, const char * category_name);
// OMITTED: CXString         clang_constructUSR_ObjCProtocol (const char * protocol_name);
// OMITTED: CXString         clang_constructUSR_ObjCIvar (const char * name, CXString classUSR);
// OMITTED: CXString         clang_constructUSR_ObjCMethod (const char * name, unsigned isInstanceMethod, CXString classUSR);
// OMITTED: CXString         clang_constructUSR_ObjCProperty (const char * property, CXString classUSR);
CXString         clang_getCursorSpelling (CXCursor C);
CXSourceRange    clang_Cursor_getSpellingNameRange (CXCursor C, unsigned pieceIndex, unsigned options);
// OMITTED: unsigned         clang_PrintingPolicy_getProperty (CXPrintingPolicy Policy, enum CXPrintingPolicyProperty Property);
// OMITTED: void             clang_PrintingPolicy_setProperty (CXPrintingPolicy Policy, enum CXPrintingPolicyProperty Property, unsigned Value);
CXPrintingPolicy clang_getCursorPrintingPolicy (CXCursor C);
void             clang_PrintingPolicy_dispose (CXPrintingPolicy Policy);
CXString         clang_getCursorPrettyPrinted (CXCursor Cursor, CXPrintingPolicy Policy);
// OMITTED: CXString         clang_getTypePrettyPrinted (CXType CT, CXPrintingPolicy cxPolicy);
// OMITTED: CXString         clang_getFullyQualifiedName (CXType CT, CXPrintingPolicy Policy, unsigned WithGlobalNsPrefix);
CXString         clang_getCursorDisplayName (CXCursor C);
CXCursor         clang_getCursorReferenced (CXCursor C);
CXCursor         clang_getCursorDefinition (CXCursor C);
unsigned         clang_isCursorDefinition (CXCursor C);
CXCursor         clang_getCanonicalCursor (CXCursor C);
// OMITTED: int              clang_Cursor_getObjCSelectorIndex (CXCursor);
// OMITTED: int              clang_Cursor_isDynamicCall (CXCursor C);
// OMITTED: CXType           clang_Cursor_getReceiverType (CXCursor C);
// OMITTED: unsigned         clang_Cursor_getObjCPropertyAttributes (CXCursor C, unsigned reserved);
// OMITTED: CXString         clang_Cursor_getObjCPropertyGetterName (CXCursor C);
// OMITTED: CXString         clang_Cursor_getObjCPropertySetterName (CXCursor C);
// OMITTED: unsigned         clang_Cursor_getObjCDeclQualifiers (CXCursor C);
// OMITTED: unsigned         clang_Cursor_isObjCOptional (CXCursor C);
// OMITTED: unsigned         clang_Cursor_isVariadic (CXCursor C);
// OMITTED: unsigned         clang_Cursor_isExternalSymbol (CXCursor C, CXString * language, CXString * definedIn, unsigned * isGenerated);
// OMITTED: CXSourceRange    clang_Cursor_getCommentRange (CXCursor C);
CXString         clang_Cursor_getRawCommentText (CXCursor C);
CXString         clang_Cursor_getBriefCommentText (CXCursor C);

// *** Token extraction and manipulation ***
// <https://clang.llvm.org/doxygen/group__CINDEX__LEX.html>

CXToken *        clang_getToken (CXTranslationUnit TU, CXSourceLocation Location);
CXTokenKind      clang_getTokenKind (CXToken Token);
CXString         clang_getTokenSpelling (CXTranslationUnit TU, CXToken Token);
CXSourceLocation clang_getTokenLocation (CXTranslationUnit TU, CXToken Token);
CXSourceRange    clang_getTokenExtent (CXTranslationUnit TU, CXToken Token);
void             clang_tokenize (CXTranslationUnit TU, CXSourceRange Range, CXToken * * Tokens, unsigned * NumTokens);
void             clang_annotateTokens (CXTranslationUnit TU, CXToken * Tokens, unsigned NumTokens, CXCursor * Cursors);
void             clang_disposeTokens (CXTranslationUnit TU, CXToken * Tokens, unsigned NumTokens);

// *** Debugging facilities ***
// <https://clang.llvm.org/doxygen/group__CINDEX__DEBUG.html>

CXString clang_getCursorKindSpelling (enum CXCursorKind Kind);
// OMITTED: void     clang_getDefinitionSpellingAndExtent (CXCursor, const char * * startBuf, const char * * endBuf, unsigned * startLine, unsigned * startColumn, unsigned * endLine, unsigned * endColumn);
// OMITTED: void     clang_enableStackTraces (void);
// OMITTED: void     clang_executeOnThread (void(*fn)(void *), void * user_data, unsigned stack_size); // NOTE: function pointer syntax not supported by the libclang-bootstrap parser

// *** Miscellaneous utility functions ***
// <https://clang.llvm.org/doxygen/group__CINDEX__MISC.html>

CXString           clang_getClangVersion (void);
// OMITTED: void               clang_toggleCrashRecovery (unsigned isEnabled);
// OMITTED: void               clang_getInclusions (CXTranslationUnit tu, CXInclusionVisitor visitor, CXClientData client_data);
CXEvalResult       clang_Cursor_Evaluate (CXCursor C);
CXEvalResultKind   clang_EvalResult_getKind (CXEvalResult E);
int                clang_EvalResult_getAsInt (CXEvalResult E);
long long          clang_EvalResult_getAsLongLong (CXEvalResult E);
unsigned           clang_EvalResult_isUnsignedInt (CXEvalResult E);
unsigned long long clang_EvalResult_getAsUnsigned (CXEvalResult E);
double             clang_EvalResult_getAsDouble (CXEvalResult E);
const char *       clang_EvalResult_getAsStr (CXEvalResult E);
void               clang_EvalResult_dispose (CXEvalResult E);
