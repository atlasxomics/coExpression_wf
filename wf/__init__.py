"""
Latch wrapper of ArchR plotEmbedding function.
"""


import subprocess
from pathlib import Path

from flytekit import LaunchPlan, task, workflow
from latch.types import LatchDir
from latch.types import LatchFile
from dataclasses import dataclass
from dataclasses_json import dataclass_json
from enum import Enum
from typing import List
from latch import large_task

class Chip(Enum):
    typeI = '50X50'
    typeII = '96X96'

@large_task
def runModule(
              chip: Chip,
              output_dir: LatchDir= 'latch://13502.account/analysis_data',
              project: str="name_of_project",
              archrObj: LatchDir= 'latch://13502.account/ArchRProjects/Rai_2_Conditions_w_shiny',
              geneList: LatchFile="latch://13502.account/noori_sample_fqs/geneList.csv"
              ) -> LatchDir:

    subprocess.run(
        [
            "Rscript",
            "/root/wf/runModuleScore.R",
            chip.value,
            archrObj.local_path,
            project,
            geneList.local_path
        ]
    )

    local_output_dir = str(Path(f"/root/").resolve())

    remote_path=output_dir.remote_path
    if remote_path[-1] != "/":
        remote_path += "/"

    return LatchDir(local_output_dir,remote_path)


@workflow
def coExpression_wf(
                    chip: Chip,
                    output_dir: LatchDir='latch://13502.account/analysis_data',
                    project: str="name_of_project",
                    archrObj: LatchDir= LatchDir('latch://13502.account/ArchRProjects/Rai_2_Conditions_w_shiny'),
                    geneList: LatchFile="latch://13502.account/noori_sample_fqs/geneList.csv"
                    ) -> LatchDir:
    """is a full-featured software suite for the analysis of single-cell chromatin accessibility data.

    coExpression
    ----

    `coExpression` is a full-featured application for projection of gene set group in Dimension Reduction plots.


    __metadata__:
        display_name: coExpression
        author:
            name: Noori
            email: noorisotude@gmail.com
            github: https://github.com/atlasxomics/coExpression_wf
        repository: https://github.com/atlasxomics/coExpression_wf
        license:
            id: MIT

    Args:

        chip:
          what size is chip that used.
          __metadata__:
            display_name: Chip size


        archrObj:
          Select the folder that produced by create ArchRProject. This folder must be included in combined.rds file.

          __metadata__:
            display_name: create ArchRProject dir

        project:
          specify a name for the output folder.chip:
          what size is chip that used.

          __metadata__:
            display_name: Project Name

        geneList:
          insert gene names list csv file.

          __metadata__:
            display_name: Gene List CSV File

        output_dir:
          Where to save the plots?.

          __metadata__:
            display_name: Output Directory
        

    """
    return runModule(
                     chip=chip,
                     archrObj=archrObj,
                     output_dir=output_dir,
                     project=project,
                     geneList=geneList)



