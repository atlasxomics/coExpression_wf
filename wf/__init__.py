"""Latch wrapper of ArchR plotEmbedding function.
"""

import glob
import logging
import subprocess

from enum import Enum
from flytekit import workflow
from latch import large_task
from latch.resources.launch_plan import LaunchPlan
from latch.types import LatchDir, LatchFile
from pathlib import Path


logging.basicConfig(
    format="%(levelname)s - %(asctime)s - %(message)s", level=logging.INFO
)


class Chip(Enum):
    typeI = "50X50"
    typeII = "96X96"
    typeIII = "220x220"


@large_task
def runModule(
    chip: Chip,
    output_dir: LatchDir,
    project: str,
    archrObj: LatchDir,
    geneList: LatchFile
) -> LatchDir:

    # Move ArchRProj folder to ~; ensures path consistent with BPCells object
    logging.info("Moving ArchRProject to /root/...")
    proj_name = archrObj.remote_path.split("/")[-1]
    new_path = f"/root/{proj_name}/"
    subprocess.run(["mv", archrObj.local_path, new_path])

    logging.info("Running module score script...")
    subprocess.run(
        [
            "Rscript",
            "/root/wf/runModuleScore.R",
            chip.value,
            new_path,
            project,
            geneList.local_path
        ]
    )

    local_output_dir = Path(glob.glob("*results")[0]).resolve()

    remote_path = output_dir.remote_path
    if remote_path[-1] != "/":
        remote_path += "/"

    return LatchDir(local_output_dir, remote_path)


@workflow
def coExpression_wf(
    chip: Chip,
    output_dir: LatchDir,
    project: str,
    archrObj: LatchDir,
    geneList: LatchFile = "latch://13502.account/sample_fqs/geneList.csv"
) -> LatchDir:
    """

    module score
    ----

    **module score** is an application for projection of gene set group in
    Dimension Reduction plots.

    __metadata__:
        display_name: module score
        author:
            name: Noori
            email: noorisotude@gmail.com
            github: https://github.com/atlasxomics/coExpression_wf
        repository: https://github.com/atlasxomics/coExpression_wf
        license:
            id: MIT

    Args:

        chip:
          What size is chip that used?
          __metadata__:
            display_name: Chip size

        archrObj:
          Select the folder that produced by create ArchRProject. This folder
          must be included in combined.rds file.

          __metadata__:
            display_name: create ArchRProject dir

        project:
          Specify a name for the output folder.

          __metadata__:
            display_name: Project Name

        geneList:
          Gene names listed in a csv.

          __metadata__:
            display_name: Gene List CSV

        output_dir:
          Latch file path to save outputs

          __metadata__:
            display_name: Output Directory

    """

    return runModule(
        chip=chip,
        archrObj=archrObj,
        output_dir=output_dir,
        project=project,
        geneList=geneList
    )


LaunchPlan(
    coExpression_wf,
    "module-score_demo",
    {
        "chip": Chip.typeI,
        "archrObj": LatchDir("latch:///ArchRProjects/module-score_demo"),
        "project": "module-score_demo",
        "geneList": "latch://13502.account/sample_fqs/geneList.csv",
        "output_dir": LatchDir("latch:///analysis_data/module-score_demo")
    }
)

if __name__ == "__main__":

    runModule(
        chip=Chip.typeII,
        output_dir="latch://13502.account/analysis_data",
        project="jm_dev_fix",
        archrObj="latch://13502.account/ArchRProjects/Kelsen",
        geneList="latch://13502.account/gene_lists/Natrajan/T_cells_vector.csv"
    )
