SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspWebSheetData] 
	@SheetID	int,
	@RevisionID     int,
	@SystemDatabase varchar(100)
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
	DECLARE @Work varchar(600) --Needed to expand varchar for security query

	IF @RevisionID = 0 BEGIN
		--Get active revision id	
		SELECT @RevisionID = (SELECT ActiveRevision
	  		      FROM mbbmPlanSheet74 s
	 		      WHERE SheetID = @SheetID)
		END

	--PlanSheet
        SELECT 	p.PlanID, p.PlanKey, p.HostCompany, s.SheetKey, s.SheetID, s.SheetManager,
        	s.Description, s.Status, s.Locked,
		s.IncludeUnposted, s.IncludePendingAlloc,
		s.PlanFlowCalculation,
		s.AcctNameDesc, s.AcctNameSpacing, s.InternetEnabled,
		s.Parent, s.GeneratedBy, s.SheetType,
		s.FileName, s.ActiveRevision, s.Publish, s.TemplateLastRowID,
		s.TemplateSlaveAutoLock, p.Description as PlanDescription, 
		s.CheckedOut, s.CheckedOutTo, s.CheckedOutProcessID, s.CheckedOutProcessType
	FROM 	mbbmPlan74 p, mbbmPlanSheet74 s
	WHERE 	s.PlanID = p.PlanID AND 
		s.SheetID = @SheetID

	--Security
	DECLARE @PlanAdmin varchar(40)
	DECLARE	@SheetManager varchar(40)
	DECLARE	@PlanID int
	SELECT @PlanID = PlanID from mbbmPlanSheet74 Where SheetID = @SheetID
	SELECT @PlanAdmin =  p.PlanManager from mbbmPlan74 p Where p.PlanID = @PlanID 
	SELECT @SheetManager = sheet.SheetManager from mbbmPlanSheet74 sheet where sheet.SheetID = @SheetID
	SELECT @Work = 'SELECT u.UserID, SecLevel = Case When u.Administrator = 1 then 6 When u.UserID = ''' + @PlanAdmin + ''' then 5 '
	SELECT @Work = @Work + 'When u.UserID in (Select UserID from mbbmPlanSec where PlanID = ' + Convert(varchar(10),@PlanID) + ' and SecLevel = 2) Then 4 '
	SELECT @Work = @Work + 'When u.UserID = ''' + @SheetManager + ''' then 3 else s.SecLevel End '
	SELECT @Work = @Work + 'FROM ' + @SystemDatabase + '.dbo.mbbmvwUser u LEFT OUTER JOIN mbbmPlanSheetSec s '
	SELECT @Work = @Work + 'ON (u.UserID = s.UserID AND s.SheetID = ' + CONVERT(varchar(10),@SheetID) + ') ORDER BY UPPER(u.UserID)'
	EXEC (@Work)
	
	--View
        SELECT	SheetID, GroupKey, Type, Value
	FROM	mbbmPlanView
	WHERE	SheetID = @SheetID
	ORDER BY GroupKey, Type

	--RevisionList
	SELECT 	r.RevisionID, r.RevisionKey, CASE WHEN s.ActiveRevision = r.RevisionID THEN 1 Else 0 END AS IsActiveRevision
	FROM	mbbmPlanSheet74 s, mbbmPlanSheetRev74 r
	WHERE	s.SheetID = r.SheetID AND
		s.SheetID = @SheetID
	ORDER BY r.RevisionKey ASC

	--Revision
	SELECT 	s.SheetID, r.RevisionID, r.RevisionKey,
		CASE WHEN r.CurrentDate < 693596
			THEN CONVERT(datetime,'1/1/1900')
			Else DATEADD(dd,r.CurrentDate-693596,'1/1/1900')
		END AS RevisionCurrentDate,
		r.PrintSettings,
		r.CreatedBy, r.CreatedTime, r.UpdatedBy, r.UpdatedTime,
		r.RowIDGen, r.ParIDGen, r.RowIDFunc, r.ParIDFunc, r.BaseDateType, s.ActiveRevision, 
		CASE WHEN s.ActiveRevision = r.RevisionID THEN 1 Else 0 END AS IsActiveRevision
	FROM	mbbmPlanSheet74 s, mbbmPlanSheetRev74 r
	WHERE	s.SheetID = r.SheetID AND
		s.SheetID = @SheetID AND
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
		CASE WHEN FromDate < 693596
			THEN CONVERT(datetime,'1/1/1900')
			Else DATEADD(dd,FromDate-693596,'1/1/1900')
		END AS ColumnFromDate,
		CASE WHEN ThruDate < 693596
			THEN CONVERT(datetime,'1/1/1900')
			Else DATEADD(dd,ThruDate-693596,'1/1/1900')
		END AS ColumnThruDate,
		Valuation, Title,
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
	SELECT 	GroupKey, Description, CurrentDateType,
		CASE WHEN CurrentDate < 693596
			THEN CONVERT(datetime,'1/1/1900')
			Else DATEADD(dd,CurrentDate-693596,'1/1/1900')
		END AS GroupCurrentDate,
		YearOffset, PeriodOffset, BalanceType, BalanceCode,
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
GRANT EXECUTE ON  [dbo].[mbbmspWebSheetData] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebSheetData] TO [public]
GO
