SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glcundo.SPv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glcundo_sp] (
	@parent_id	 	smallint,
	@consol_ctrl_num	varchar(16)
) AS
 

DECLARE	@subs_id smallint, 		@max_seq int,		@seq_id int, 
	@journal_ctrl_num varchar(16),	@work_flag smallint


DELETE	glproclg
WHERE	ctrl_num = @consol_ctrl_num
AND	client_id = 121


DELETE	glerrlst
WHERE	char_parm_1 = @consol_ctrl_num
AND	client_id = 'CONSOLIDATION'


SELECT 	@max_seq = MAX( sequence_id ),
	@seq_id = MIN( sequence_id )
FROM	glcondet
WHERE	consol_ctrl_num = @consol_ctrl_num


IF	@max_seq = 0 OR @max_seq IS NULL
	RETURN

WHILE	@seq_id <= @max_seq
BEGIN
	SELECT	@journal_ctrl_num = ''

	SELECT	@journal_ctrl_num = journal_ctrl_num,
		@subs_id = subs_id,
		@work_flag = work_flag
	FROM	glcondet
	WHERE	consol_ctrl_num = @consol_ctrl_num
	AND	sequence_id = @seq_id

	
	IF	@consol_ctrl_num != ''
	BEGIN
		
		DELETE	gltrxdet
		WHERE	journal_ctrl_num = @journal_ctrl_num

		DELETE	gltrx
		WHERE	journal_ctrl_num = @journal_ctrl_num
	END

	
	UPDATE	glcocon_vw
	SET	status_type = ( @work_flag - 1 )
	WHERE	parent_comp_id = @parent_id
	AND	sub_comp_id = @subs_id

	
	SELECT	@seq_id = @seq_id + 1
END


DELETE	glcondet
WHERE	consol_ctrl_num = @consol_ctrl_num

RETURN 0







/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcundo_sp] TO [public]
GO
