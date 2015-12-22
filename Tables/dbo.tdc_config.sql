CREATE TABLE [dbo].[tdc_config]
(
[function] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mod_owner] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_confi__mod_o__7AA68BA7] DEFAULT ('UNA'),
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value_str] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		tdc_config_iu_trg		
Type:		Trigger
Description:	Write details stored in INV_EXCLUDED_BINS setting to cvo_inv_excluded_bins
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	17/09/2011	Original Version

*/

CREATE TRIGGER [dbo].[tdc_config_iu_trg] ON [dbo].[tdc_config]
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @value_str	VARCHAR(255)

	SELECT 
		@value_str = i.value_str
	FROM
		inserted i
	LEFT JOIN
		deleted d
	ON 
		i.[function] = d.[function]
		AND i.mod_owner = d.mod_owner
		AND i.value_str <> ISNULL(d.value_str,'')
	WHERE
		i.[function] = 'INV_EXCLUDED_BINS'

	IF @@ROWCOUNT <> 0
	BEGIN
		-- Create table to hold parsed string
		CREATE TABLE #bins (
			bin_no VARCHAR(12))

		-- Load table
		INSERT INTO #bins(bin_no)
		SELECT LEFT(valor,12) FROM dbo.fs_cParsing(@value_str)
		
		-- REFRESH TABLE
		-- begin transaction
		BEGIN TRAN

		-- Delete bins no longer in config
		DELETE FROM cvo_inv_excluded_bins WHERE bin_no NOT IN (SELECT bin_no FROM #bins)
	
		-- Insert new bins
		INSERT INTO cvo_inv_excluded_bins(
			location,
			bin_no)
		SELECT
			'001',
			bin_no
		FROM
			#bins
		WHERE
			bin_no NOT IN (SELECT bin_no FROM cvo_inv_excluded_bins (NOLOCK))
	
		-- Commit transactions
		COMMIT TRAN
		
		DROP TABLE #bins
	END	
END

GO
CREATE UNIQUE CLUSTERED INDEX [TDC_CONFIG_INDEX] ON [dbo].[tdc_config] ([function], [mod_owner]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_config] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_config] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_config] TO [public]
GO
