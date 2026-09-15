#!/usr/bin/env python3
"""
geo_to_mesh_vtk.py

Convert a Gmsh .geo file into two mesh output files:
    1) A .mesh file (INRIA Medit format)
    2) A .vtk  file (VTK legacy format)

Supports both 2D and 3D meshing, and optional multi-threaded meshing
using Gmsh's built-in OpenMP parallelization.

Requirements:
    - gmsh 4.11.1 (or compatible) with the Python API installed:
        pip install gmsh

Usage:
    python GEO2MESH.py input.geo --dim 3
    python GEO2MESH.py input.geo --dim 2 --threads 4
    python GEO2MESH.py input.geo --dim 3 --threads 8 --outdir results --basename mymesh

Author: (generated script)
"""

import argparse
import os
import sys

try:
    import gmsh
except ImportError:
    sys.stderr.write(
        "ERROR: The 'gmsh' Python module was not found.\n"
        "Please install it with: pip install gmsh\n"
    )
    sys.exit(1)


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description=(
            "Generate a mesh from a Gmsh .geo file and export it "
            "as both .mesh and .vtk files."
        )
    )
    parser.add_argument(
        "geo_file",
        type=str,
        help="Path to the input .geo file.",
    )
    parser.add_argument(
        "--dim",
        type=int,
        choices=[2, 3],
        required=True,
        help="Mesh dimension: 2 for a 2D mesh, 3 for a 3D mesh.",
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=1,
        help=(
            "Number of threads to use for parallel meshing. "
            "Default is 1 (single-threaded). Values greater than 1 "
            "enable Gmsh's OpenMP-based parallel meshing algorithms "
            "(e.g. HXT for 3D Delaunay meshing)."
        ),
    )
    parser.add_argument(
        "--outdir",
        type=str,
        default=".",
        help="Output directory for the generated .mesh and .vtk files. "
             "Default is the current directory.",
    )
    parser.add_argument(
        "--basename",
        type=str,
        default=None,
        help="Base name (without extension) for the output files. "
             "Default: same as the input .geo file name.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose Gmsh terminal output during meshing.",
    )

    return parser.parse_args()


def validate_inputs(args):
    """Validate command-line arguments before running Gmsh."""
    if not os.path.isfile(args.geo_file):
        raise FileNotFoundError(f"Input .geo file not found: {args.geo_file}")

    if not args.geo_file.lower().endswith(".geo"):
        sys.stderr.write(
            f"WARNING: Input file '{args.geo_file}' does not have a "
            ".geo extension. Attempting to proceed anyway.\n"
        )

    if args.threads < 1:
        raise ValueError("The number of threads must be a positive integer (>= 1).")

    os.makedirs(args.outdir, exist_ok=True)


def set_fixed_mesh_options():
    """
    Apply the mesh options that must always be enabled, regardless of
    the mesh dimension, thread count, or any other runtime settings.

    Options:
        Mesh.FirstNodeTag    = 1  -> Node numbering starts at 1.
        Mesh.FirstElementTag = 1  -> Element numbering starts at 1.
        Mesh.Algorithm       = 5  -> 2D meshing algorithm: Delaunay.
        Mesh.Algorithm3D     = 1  -> 3D meshing algorithm: Delaunay.
        Mesh.OptimizeNetgen  = 3  -> Netgen-based mesh optimization
                                     passes (applied after meshing).
    """
    gmsh.option.setNumber("Mesh.FirstNodeTag", 1)
    gmsh.option.setNumber("Mesh.FirstElementTag", 1)
    gmsh.option.setNumber("Mesh.Algorithm", 5)
    gmsh.option.setNumber("Mesh.Algorithm3D", 1)
    gmsh.option.setNumber("Mesh.OptimizeNetgen", 3)


def configure_threads(num_threads):
    """
    Configure Gmsh to use the specified number of threads for meshing.

    Gmsh uses OpenMP internally for several meshing algorithms
    (e.g. the HXT 3D Delaunay algorithm, and some 2D algorithms).
    Setting General.NumThreads controls the global thread pool,
    while the Mesh.MaxNumThreads1D/2D/3D options control per-dimension
    parallelization limits.
    """
    gmsh.option.setNumber("General.NumThreads", num_threads)
    gmsh.option.setNumber("Mesh.MaxNumThreads1D", num_threads)
    gmsh.option.setNumber("Mesh.MaxNumThreads2D", num_threads)
    gmsh.option.setNumber("Mesh.MaxNumThreads3D", num_threads)


def generate_mesh(geo_file, dim, num_threads, verbose):
    """
    Load the .geo file and generate a mesh of the requested dimension.

    Parameters:
        geo_file (str): Path to the input .geo file.
        dim (int): Mesh dimension (2 or 3).
        num_threads (int): Number of threads to use for meshing.
        verbose (bool): Whether to print Gmsh's terminal output.
    """
    gmsh.initialize()

    try:
        gmsh.option.setNumber("General.Terminal", 1 if verbose else 0)

        # Apply the mesh options that must always be enabled.
        set_fixed_mesh_options()

        # Configure multi-threaded meshing (no-op if num_threads == 1).
        configure_threads(num_threads)

        # Open (parse) the .geo file. This executes the geometry script
        # and builds the model, without generating a mesh yet.
        gmsh.open(geo_file)

        # Generate the mesh for the requested dimension.
        gmsh.model.mesh.generate(dim)

    except Exception as exc:
        gmsh.finalize()
        raise RuntimeError(f"Mesh generation failed: {exc}") from exc

    return gmsh


def export_mesh(mesh_module, outdir, basename):
    """
    Export the generated mesh to both .mesh (Medit) and .vtk (VTK legacy)
    formats.

    Parameters:
        mesh_module: The initialized gmsh module (already holds the mesh).
        outdir (str): Output directory.
        basename (str): Base file name without extension.

    Returns:
        (str, str): Paths to the generated .mesh and .vtk files.
    """
    mesh_path = os.path.join(outdir, f"{basename}.mesh")
    vtk_path = os.path.join(outdir, f"{basename}.vtk")

    try:
        mesh_module.write(mesh_path)
        mesh_module.write(vtk_path)
    except Exception as exc:
        raise RuntimeError(f"Failed to write output files: {exc}") from exc

    return mesh_path, vtk_path


def main():
    args = parse_arguments()

    try:
        validate_inputs(args)
    except (FileNotFoundError, ValueError) as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        sys.exit(1)

    basename = args.basename or os.path.splitext(os.path.basename(args.geo_file))[0]

    print(f"Loading geometry file: {args.geo_file}")
    print(f"Target mesh dimension: {args.dim}D")
    print(f"Number of threads: {args.threads}")

    try:
        mesh_module = generate_mesh(
            geo_file=args.geo_file,
            dim=args.dim,
            num_threads=args.threads,
            verbose=args.verbose,
        )
    except RuntimeError as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        sys.exit(1)

    try:
        mesh_path, vtk_path = export_mesh(mesh_module, args.outdir, basename)
    except RuntimeError as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        mesh_module.finalize()
        sys.exit(1)

    mesh_module.finalize()

    print("Mesh generation completed successfully.")
    print(f"  -> {mesh_path}")
    print(f"  -> {vtk_path}")


if __name__ == "__main__":
    main()
