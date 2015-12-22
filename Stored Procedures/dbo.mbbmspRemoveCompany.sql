SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspRemoveCompany] 
	@HostCompany            mbbmudtCompanyCode
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

	DELETE mbbmAccountDimensions74 WHERE HostCompany = @HostCompany
	DELETE mbbmParameters WHERE HostCompany = @HostCompany
	DELETE mbbmFormulaQryTables74 WHERE HostCompany = @HostCompany
	DELETE mbbmFormulaAccountDim WHERE HostCompany = @HostCompany
	DELETE mbbmFormulaPubQry WHERE HostCompany = @HostCompany
	DELETE mbbmFormulaQry74 WHERE HostCompany = @HostCompany
	DELETE mbbmFormulaLines74 WHERE HostCompany = @HostCompany
	DELETE mbbmFormula74 WHERE HostCompany = @HostCompany
	DELETE mbbmOLAPLevelPeriods61 WHERE HostCompany = @HostCompany
	DELETE mbbmOLAPDimLevels75 WHERE HostCompany = @HostCompany
	DELETE mbbmOLAPDimensions61 WHERE HostCompany = @HostCompany

	DELETE mbbmPlanCol7 WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanCustCol7 WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanHfc WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanGrp74 WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanColSet WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanSheetSections WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanHist WHERE RevisionID IN 
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanSheetDimensions74 WHERE RevisionID IN
		(SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID IN
			(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
				(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)))
	DELETE mbbmPlanSheetRev74 WHERE SheetID IN
		(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
			(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmPlanSheetSec WHERE SheetID IN
		(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
			(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmTemplateValues WHERE SheetID IN
		(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
			(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmTemplateSheets WHERE SheetID IN
		(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
			(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmPlanView WHERE SheetID IN
		(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
			(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmPlanHist WHERE SheetID IN
		(SELECT SheetID FROM mbbmPlanSheet74 WHERE PlanID IN 
			(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmPlanSheet74 WHERE PlanID IN 
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)
	DELETE mbbmPlanHist WHERE PlanID IN 
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)
	DELETE mbbmPlanSec WHERE PlanID IN 
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)
	DELETE mbbmOLAPSecurityCell WHERE HostCompany = @HostCompany AND CubeName IN
		(SELECT Name FROM mbbmCubes75 WHERE HostCompany = @HostCompany AND 
                PlanID IN 
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmOLAPSecurityCube WHERE HostCompany = @HostCompany AND CubeName IN
		(SELECT Name FROM mbbmCubes75 WHERE HostCompany = @HostCompany AND 
                PlanID IN 
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))

	DELETE mbbmOLAPSecurityRole WHERE HostCompany = @HostCompany

	DELETE mbbmCubeDimAttributes WHERE HostCompany = @HostCompany AND CubeName IN
		(SELECT Name FROM mbbmCubes75 WHERE HostCompany = @HostCompany AND 
                PlanID IN 
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany))
	DELETE mbbmCubes75 WHERE PlanID IN
		(SELECT PlanID FROM mbbmPlan74 WHERE HostCompany = @HostCompany)
	DELETE mbbmPlan74 WHERE HostCompany = @HostCompany
	DELETE mbbmSheetStatusCode6 WHERE HostCompany = @HostCompany

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspRemoveCompany] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspRemoveCompany] TO [public]
GO
