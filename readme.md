# SharePoint 2016 Automation Toolkit
Sample Farm Build and Workpad to support demos.  

For SharePoint 2016.  

There is a seperate version for SharePoint 2013 which replicates "MinRole" roles. This one is "better" becasue there is less script.  

## Notes
A WHOLE BUNCH is done to support flexibility in the controller.  
Some things are done to support DEMOS - i.e. time savers when presenting the demo.  

It is intended to support initial farm build, but more importantly ongoing work with the farm.  
It is NOT a build automation solution.

## Remoting
You need it!

## Explanation
May (or may not!) come in the future.  

It all started during the (very) early days of SP2016 when Microsoft asked me to help with functional and scenario testing for MinRole and other related topology changes in the product, whilst the hosting was in an environment without snapshots. In order to very rapidly build out 10-18 server farms, I took an existing toolkit for customer 2013 deployments and stripped it down to make this version. End to end farm. SSL correct. Load Balancing support, regardless of device used. All that sort of thing. Most of that was already in the previous kit. As MinRole progresses there were a variety of tweaks and otherwise esoteric or subtle elements for which testing was key - mostly in respect to the Search roles as well as outliers (DC, C2WTS, CA etc). Lots of things are different about how MinRole is implemented in the on premises product and they all needed putting through thier paces, and also deal with discovery of custom solution dependencies and service relationships.  

The toolkit aside from provisioning a ten server farm in one hour, allows for the "workpad" approach. You can initailise the script and be up and working in a console with all the elements needed (creds, objects etc). Also the "sections" allow for rapid injection of additional testing tasks (PSC, B2B, other tweaks for security and so forth). It enables repeated scenario testing at the various stages of deployment, with or without snapshots (but hopefully with!).  

There's lots wrong with it. But it is now intended primarily as a learning tool, and to support a variety of workshop style events at conferences and so forth.  

There is no intent to significantly invest in this toolkit.  In the near future key capabilty will be moved to PowerShell Modules under a "Infrastrucutre Tools" banner. More info on that when it's ready.
