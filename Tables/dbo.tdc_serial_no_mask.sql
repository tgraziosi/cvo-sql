CREATE TABLE [dbo].[tdc_serial_no_mask]
(
[mask_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mask_data] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_serial_no_mask_tg] ON [dbo].[tdc_serial_no_mask]
FOR  DELETE , UPDATE
	
AS

DECLARE 	@strDefault_Mask_Code		AS VARCHAR (15),
		 @strMask_Code		AS VARCHAR (15)


SELECT @strDefault_Mask_Code = 'NONE'


 
IF UPDATE (mask_code) OR UPDATE(mask_data)
	BEGIN
		SELECT @strMask_Code = mask_code FROM INSERTED

		IF @strMask_Code = @strDefault_Mask_Code
		BEGIN
			IF @@TRANCOUNT > 0
			BEGIN
				ROLLBACK TRAN
			END
			RAISERROR ('Cannot alter the Default Mask Code. ',16,1)
		END
	END


ELSE
	BEGIN
		SELECT @strMask_Code = mask_code FROM DELETED

		IF @strMask_Code = @strDefault_Mask_Code
		BEGIN
			IF @@TRANCOUNT > 0
			BEGIN
				ROLLBACK TRAN
			END	
			RAISERROR ('Cannot delete the Default Mask Code. ',16,1)
		END
	END
GO
CREATE UNIQUE CLUSTERED INDEX [tdc_serial_no_idx] ON [dbo].[tdc_serial_no_mask] ([mask_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_serial_no_mask] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_serial_no_mask] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_serial_no_mask] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_serial_no_mask] TO [public]
GO
