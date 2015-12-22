SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[ep_segment_init_data] as 
BEGIN	

	if ((select count(*) from CVO_Control..epsegmentguid
	where seg_name = 'coa segment guid') = 0)
		insert CVO_Control..epsegmentguid (seg_name)
			select 'coa segment guid'

	if ((select count(*) from CVO_Control..epsegmentguid
	where seg_name = 'reference segment guid') = 0)
		insert CVO_Control..epsegmentguid (seg_name)
			select 'reference segment guid'

	if ((select count(*) from CVO_Control..epsegmentguid
	where seg_name = 'company segment guid') = 0)
		insert CVO_Control..epsegmentguid (seg_name)
			select 'company segment guid'

END

GO
GRANT EXECUTE ON  [dbo].[ep_segment_init_data] TO [public]
GO
