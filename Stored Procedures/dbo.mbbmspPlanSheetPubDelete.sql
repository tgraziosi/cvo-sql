SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanSheetPubDelete]
	@SheetID        int             = 0,
        @PublicationDatabase varchar(100) = " ",
	@PubTablesOnly tinyint = 0
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
	DECLARE @CubeName		varchar(60)
	DECLARE @DimSet			varchar(255)
	DECLARE @HostCompany            mbbmudtCompanyCode
	DECLARE @PlanID			int
	DECLARE @Work                   varchar(200)
	DECLARE @SheetLookupID          int
        
	DECLARE crsCube CURSOR FOR
	SELECT p.HostCompany, p.SheetID, c.Name
        FROM mbbmPlanSheet74 p, mbbmCubes75 c
        WHERE p.SheetID = @SheetID
        AND c.HostCompany = p.HostCompany
        AND c.PlanID = p.PlanID
	
	OPEN    crsCube
	FETCH   crsCube
	INTO    @HostCompany, @SheetLookupID, @CubeName
	  WHILE (@@FETCH_STATUS = 0) BEGIN
            SELECT @Work = @PublicationDatabase + '..mbbmspFactDataDelete'
            EXEC @Work @CubeName, @SheetLookupID
            FETCH   crsCube
            INTO    @HostCompany, @SheetLookupID, @CubeName
          END
        CLOSE crsCube
        DEALLOCATE crsCube

	--Delete Publication Related Items
	DECLARE crsDeleted CURSOR FOR
	SELECT p.HostCompany, p.PlanID
        FROM mbbmPlanSheet74 p
        WHERE p.SheetID = @SheetID

	OPEN    crsDeleted
	FETCH   crsDeleted
	INTO    @HostCompany, @PlanID
	WHILE (@@FETCH_STATUS = 0) BEGIN

          SELECT @Work = @PublicationDatabase + '..mbbmspPublicationDelete'
          EXEC mbbmspSheetDimensionSet @SheetID, @DimSet OUTPUT
          EXEC @Work @HostCompany, @PlanID, @SheetID, 0, 0, @DimSet

          FETCH   crsDeleted
          INTO    @HostCompany, @PlanID
	  SELECT @@FETCH_STATUS
        END
        CLOSE crsDeleted
        DEALLOCATE crsDeleted

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetPubDelete] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetPubDelete] TO [public]
GO
