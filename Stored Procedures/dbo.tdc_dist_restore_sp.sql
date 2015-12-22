SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.tdc_dist_seq_restore    Script Date: 3/14/99 12:04:35 PM ******/
CREATE PROCEDURE [dbo].[tdc_dist_restore_sp]
@RestoreType	int
AS

IF(@RestoreType = 0)
BEGIN
	TRUNCATE TABLE tdc_dist_method
	INSERT INTO tdc_dist_method(method, [description]) VALUES('01','Pick - Verify Order')
	INSERT INTO tdc_dist_method(method, [description]) VALUES('02','Pick - Stage - Verify')
	INSERT INTO tdc_dist_method(method, [description]) VALUES('03','Pick to Stage - Verify')

	TRUNCATE TABLE tdc_dist_control_seq
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('01','001','O1','U','Picking')
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('01','002','V1','G','Verify Order')
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('02','001','O1','U','Picking')
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('02','002','S1','G','Staging')
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('02','003','V1','P','Ship Verify')
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('03','001','O1','G','Picking')
	INSERT INTO tdc_dist_control_seq(method, [sequence], [function], lvl, [description]) VALUES('03','002','V1','P','Ship Verify')
END

IF(@RestoreType = 1)
BEGIN
	TRUNCATE TABLE tdc_dist_modules
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('Q1', 'Received into Supply Chain Execution')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('O1', 'Picking')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('P1', 'Packing')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('N1', 'Cartonizing')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('M1', 'Manifesting')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('S1', 'Staging')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('V1', 'Ship Verify')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('E1', 'EDI ASN 856')
	INSERT INTO tdc_dist_modules(module_code, [description]) VALUES('R1', 'Shipping')
END
GO
GRANT EXECUTE ON  [dbo].[tdc_dist_restore_sp] TO [public]
GO
