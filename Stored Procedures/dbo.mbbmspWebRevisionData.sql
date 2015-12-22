SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspWebRevisionData] 
	@RevisionID     int
WITH ENCRYPTION
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/

	--RevisionList
	DECLARE @SheetID integer
	select @SheetID=SheetID from mbbmPlanSheetRev74 WHERE RevisionID = @RevisionID
	SELECT 	r.RevisionID, r.RevisionKey, CASE WHEN s.ActiveRevision = r.RevisionID THEN 1 Else 0 END AS IsActiveRevision
	FROM	mbbmPlanSheet74 s, mbbmPlanSheetRev74 r
	WHERE	s.SheetID = r.SheetID AND
		s.SheetID = @SheetID
	ORDER BY r.RevisionKey ASC

	--Revision
	SELECT 	s.SheetID, r.RevisionID, r.RevisionKey, DATEADD(dd,r.CurrentDate-693596,'1/1/1900') RevisionCurrentDate, r.PrintSettings,
		r.CreatedBy, r.CreatedTime, r.UpdatedBy, r.UpdatedTime,
		r.RowIDGen, r.ParIDGen, r.RowIDFunc, r.ParIDFunc, r.BaseDateType, s.ActiveRevision, 
		CASE WHEN s.ActiveRevision = r.RevisionID THEN 1 Else 0 END AS IsActiveRevision
	FROM	mbbmPlanSheet74 s, mbbmPlanSheetRev74 r
	WHERE	s.SheetID = r.SheetID AND
		r.RevisionID = @RevisionID

	--SheetDim
	SELECT	Code, CASE WHEN LEFT(Code,7) = 'AcctDim' THEN 1 Else 0 END AS SystemDimension,
		TierCode, GroupCode, FromValue, ThruValue, Flags, Mask LastMask, Length
	FROM 	mbbmPlanSheetDimensions74
	WHERE	RevisionID = @RevisionID AND
		Axis = 0
	ORDER BY Member

	--RowDim
	SELECT	Code, CASE WHEN LEFT(Code,7) = 'AcctDim' THEN 1 Else 0 END AS SystemDimension,
		TierCode, GroupCode, FromValue, ThruValue, Flags, Mask LastMask, Length
	FROM 	mbbmPlanSheetDimensions74
	WHERE	RevisionID = @RevisionID AND
		Axis = 1
	ORDER BY Member

	--ColumnDim
	SELECT	Code, CASE WHEN LEFT(Code,7) = 'AcctDim' THEN 1 Else 0 END AS SystemDimension,
		TierCode, GroupCode, FromValue, ThruValue, Flags, Mask LastMask, Length
	FROM 	mbbmPlanSheetDimensions74
	WHERE	RevisionID = @RevisionID AND
		Axis = 2
	ORDER BY Member

	--Column
	SELECT 	ColumnKey, GroupKey, Description,
		FromPeriodType, FromPeriod, FromPeriodAct, ThruPeriodType, ThruPeriod, ThruPeriodAct,
		DATEADD(dd,FromDate-693596,'1/1/1900') ColumnFromDate, DATEADD(dd,ThruDate-693596,'1/1/1900') ColumnThruDate, Valuation, Title,
		DimValue1, DimValue2, DimValue3, DimValue4, ColSetKey
	FROM 	mbbmPlanCol7
	WHERE 	RevisionID = @RevisionID
	ORDER BY Position

	--CustomColumn
	SELECT	ColumnKey, Description, Title, DimCode, DimAttrName, DataType, TextFormat, TypeDateSeparator, TypeDateCentury, ColSetKey
	FROM 	mbbmPlanCustCol7
	WHERE	RevisionID = @RevisionID
	ORDER BY Position

	--Group
	SELECT 	GroupKey, Description, CurrentDateType, DATEADD(dd,CurrentDate-693596,'1/1/1900') GroupCurrentDate, YearOffset, PeriodOffset, BalanceType, BalanceCode,
		ModelOrder, ModelColumnPrefix, ModelColumnDescription, ModelValuation, ModelFromPeriodType, ModelFromPeriod, ModelThruPeriodType, ModelThruPeriod,
		ModelLastFromPeriod, ModelLastThruPeriod, ModelFromIncrement, ModelThruIncrement, ModelLayoutStyle, ModelColumnTotal, Publish, GroupCalculation,
		MeasureName, ModelViewColumn, ModelViewTotal, UsePlanBudgetCode
	FROM	mbbmPlanGrp74
	WHERE 	RevisionID = @RevisionID

	--ColSet
	SELECT	ColSetKey, Description
	FROM	mbbmPlanColSet
	WHERE	RevisionID = @RevisionID

	--HeaderFooter
        SELECT 	CellType, Section, Line, Text, FontName, FontSize, FontAttrib
	FROM	mbbmPlanHfc
	WHERE	RevisionID = @RevisionID

	--Section
	SELECT 	SectionKey
	FROM 	mbbmPlanSheetSections
        WHERE	RevisionID = @RevisionID

	--AllowMultiCurrency
	SELECT 	1 as AllowMultiCurrency

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebRevisionData] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebRevisionData] TO [public]
GO
