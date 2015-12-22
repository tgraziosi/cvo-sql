SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imapvnd_vw] AS SELECT * from [CVO_Control]..imapvnd	


                                             
GO
GRANT REFERENCES ON  [dbo].[imapvnd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imapvnd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imapvnd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imapvnd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imapvnd_vw] TO [public]
GO
