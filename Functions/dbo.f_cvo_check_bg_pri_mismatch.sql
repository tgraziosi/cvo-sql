SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Tine Graziosi>
-- Create date: <March 26, 2019>
-- Description:	<Check for BG primary designation mismatch
-- =============================================
CREATE FUNCTION [dbo].[f_cvo_check_bg_pri_mismatch]
(
    @bg VARCHAR(10),
    @pri VARCHAR(10)
)
RETURNS VARCHAR(10) -- "mismatch" or ""
AS
BEGIN

    DECLARE @mismatch VARCHAR(10);
    SELECT @mismatch = '';

    SELECT @mismatch = CASE
                           WHEN (
                                    @pri = 'bbg'
                                    AND ISNULL(@bg, '') <> '000502'
                                )
                                OR
                                (
                                    @pri = 'ce'
                                    AND ISNULL(@bg, '') <> '000507'
                                )
                                OR
                                (
                                    @pri IN ( 'fec-a', 'fec-m' )
                                    AND ISNULL(@bg, '') <> '000550'
                                )
                                OR
                                (
                                    @pri IN ( 'oogp' )
                                    AND ISNULL(@bg, '') <> '000542'
                                )
                                OR
                                (
                                    @pri IN ( 'villa' )
                                    AND ISNULL(@bg, '') <> '000549'
                                )
                                OR
                                (
                                    @pri IN ( 'vwest' )
                                    AND ISNULL(@bg, '') <> '000563'
                                ) THEN
                               'mismatch'
                           ELSE
                               ''
                       END;

    RETURN @mismatch;

END;

GO
