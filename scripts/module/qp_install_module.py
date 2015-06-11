#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Usage: qp_install_module.py list [--installed|--avalaible-local|--avalaible-remote]
       qp_install_module.py install -n <name>
       qp_install_module.py create -n <name> [<children_module>...]
       qp_install_module.py download -n <name> [<path_folder>...]


Options:
    list: List all the module avalaible
    create: Create a new module
"""

import sys
import os

try:
    from docopt import docopt
    from module_handler import ModuleHandler, get_dict_child
    from module_handler import get_l_module_descendant
    from update_README import Doc_key, Needed_key
except ImportError:
    print "source .quantum_package.rc"
    raise


def save_new_module(path, l_child):

    # ~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~ #
    # N E E D E D _ C H I L D R E N _ M O D U L E S #
    # ~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~ #

    try:
        os.makedirs(path)
    except OSError:
        print "The module ({0}) already exist...".format(path)
        sys.exit(1)

    with open(os.path.join(path, "NEEDED_CHILDREN_MODULES"), "w") as f:
        f.write(" ".join(l_child))
        f.write("\n")

    # ~#~#~#~#~#~#~ #
    # R E A D _ M E #
    # ~#~#~#~#~#~#~ #

    module_name = os.path.basename(path)

    header = "{0}\n{1}\n{0}\n".format("=" * len(module_name), module_name)

    with open(os.path.join(path, "README.rst"), "w") as f:
        f.write(header + "\n")
        f.write(Doc_key + "\n")
        f.write(Needed_key + "\n")


if __name__ == '__main__':
    arguments = docopt(__doc__)
    qp_root_src = os.path.join(os.environ['QP_ROOT'], "src")
    qp_root_plugin = os.path.join(os.environ['QP_ROOT'], "plugins")

    if arguments["list"]:

        if arguments["--installed"]:
            l_repository = [qp_root_src]

        m_instance = ModuleHandler(l_repository)

        for module in m_instance.l_module:
            print module

    elif arguments["create"]:
        m_instance = ModuleHandler(l_repository)

        l_children = arguments["<children_module>"]

        qp_root = os.environ['QP_ROOT']
        path = os.path.join(qp_root_src, arguments["<name>"])

        print "You will create the module:"
        print path

        for children in l_children:
            if children not in m_instance.dict_descendant:
                print "This module ({0}) is not a valide module.".format(children)
                print "Run `list` flag for the list of module avalaible"
                print "Aborting..."
                sys.exit(1)

        print "You ask for this submodule:"
        print l_children

        print "You can use all the routine in this module"
        print l_children + m_instance.l_descendant_unique(l_children)

        print "This can be reduce to:"
        l_child_reduce = m_instance.l_reduce_tree(l_children)
        print l_child_reduce
        save_new_module(path, l_child_reduce)

    elif arguments["download"]:

        d_local = get_dict_child([qp_root_src])
        d_remote = get_dict_child(arguments["<path_folder>"])

        d_child = d_local.copy()
        d_child.update(d_remote)

        name = arguments["<name>"]
        l_module_descendant = get_l_module_descendant(d_child, [name])

        for module in l_module_descendant:
            if module not in d_local:
                print "you need to install", module

    elif arguments["install"]:

        d_local = get_dict_child([qp_root_src])

        d_plugin = get_dict_child([qp_root_plugin])

        d_child = d_local.copy()
        d_child.update(d_plugin)

        name = arguments["<name>"]
        l_module_descendant = get_l_module_descendant(d_child, [name])

        module_to_cp = [module for module in l_module_descendant if module not in d_local]

        print "For ln -s by hand the module"
        print module_to_cp