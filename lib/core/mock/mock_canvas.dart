import '../models.dart';
import '../services.dart';

/// Stand-in for the Canvas REST API. Returns fresh objects on every call,
/// like a real network response.
class MockCanvas implements LmsProvider {
  @override
  String get name => 'Canvas';

  @override
  String get host => 'eui.instructure.com';

  @override
  Future<List<Course>> listCourses() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return [
      for (final c in _courses)
        Course(
          id: c.id,
          code: c.code,
          name: c.name,
          term: 'Fall 2026',
          files: [
            for (final f in c.files)
              CourseFile(id: f.id, courseId: c.id, name: f.name, kind: f.kind, sourceTokens: f.tokens),
          ],
        ),
    ];
  }

  @override
  Future<String> fetchFileText(CourseFile file) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (final c in _courses) {
      for (final f in c.files) {
        if (f.id == file.id) return f.text;
      }
    }
    throw StateError('File ${file.id} not found on Canvas');
  }
}

class _F {
  const _F(this.id, this.name, this.kind, this.tokens, this.text);
  final String id, name, kind, text;
  final int tokens;
}

class _C {
  const _C(this.id, this.code, this.name, this.files);
  final String id, code, name;
  final List<_F> files;
}

const _courses = [
  _C('cs201', 'CS201', 'Data Structures', [
    _F('cs201-w3', 'Week 3 - Binary Search Trees.pdf', 'pdf', 14200, '''
## What is a binary search tree
A binary search tree (BST) is a binary tree where every node's left subtree holds only smaller keys and its right subtree holds only larger keys. This ordering property must hold at every node, not just the root.
## Searching a BST
To search for a key, start at the root and compare. If the key is smaller, go left; if it is larger, go right; if it is equal, you found it. Each comparison discards a whole subtree, so a search follows a single path from the root down.
## Inserting a key
Insertion follows the same path as search until it reaches an empty child position, then places the new node there. New keys are always inserted as leaves, so existing nodes never move.
## Deleting a key
Deleting a leaf is trivial. Deleting a node with one child splices that child into its place. Deleting a node with two children replaces its key with its in-order successor, the smallest key in its right subtree, and then deletes the successor.
## Complexity and balance
Search, insert and delete all cost O(h), where h is the height of the tree. A balanced tree has h = O(log n), but inserting keys in sorted order produces a degenerate tree shaped like a linked list with h = n. Self-balancing trees such as AVL and red-black trees keep h = O(log n).
'''),
    _F('cs201-w4', 'Week 4 - Heaps and Priority Queues.pptx', 'slides', 11800, '''
## Priority queue
A priority queue returns the element with the highest priority first, regardless of insertion order. Typical operations are insert, peek and extract-min.
## The heap property
A binary min-heap is a complete binary tree where every parent is smaller than or equal to its children. The minimum is always at the root. A heap is stored in an array: the children of index i are at 2i+1 and 2i+2.
## Insert and sift-up
Insert places the new key at the next free array slot, then swaps it with its parent while it is smaller than the parent. This takes O(log n).
## Extract-min and sift-down
Extract-min removes the root, moves the last element to the root, then swaps it with its smaller child until the heap property holds. This also takes O(log n).
## Heapsort
Heapsort builds a heap in O(n) and then extracts the minimum n times, sorting in O(n log n) with no extra memory.
'''),
    _F('cs201-a2', 'Assignment 2 - Implement a BST.pdf', 'assignment', 3100, '''
## Task
Implement a binary search tree class supporting insert, search, delete and in-order traversal.
## Requirements
Deletion must handle all three cases: leaf, one child and two children. In-order traversal must return keys in ascending order. Include tests for inserting sorted input.
## Grading
Correctness 60 percent, tests 25 percent, code quality 15 percent.
## Deadline
Submit on Canvas by Sunday 4 October 2026 at 23:59.
'''),
  ]),
  _C('math203', 'MATH203', 'Linear Algebra', [
    _F('math203-l5', 'Lecture 5 - Eigenvalues and Eigenvectors.pdf', 'pdf', 16400, '''
## Definition
An eigenvector of a square matrix A is a non-zero vector v such that Av = λv for some scalar λ, called its eigenvalue. Multiplying by A only stretches or flips an eigenvector; it never changes its direction.
## The characteristic polynomial
Eigenvalues are the roots of det(A - λI) = 0. For a 2x2 matrix this is a quadratic, λ² - trace(A)λ + det(A) = 0.
## Geometric meaning
Eigenvectors are the directions a linear transformation leaves on their own line. The eigenvalue is the stretch factor along that line; a negative eigenvalue flips the vector.
## Worked example
For A = [[2, 1], [1, 2]] the characteristic polynomial is λ² - 4λ + 3, so λ = 1 and λ = 3. The eigenvector for λ = 3 is (1, 1) and for λ = 1 it is (1, -1).
'''),
    _F('math203-l6', 'Lecture 6 - Diagonalization.pdf', 'pdf', 13900, '''
## When a matrix is diagonalizable
An n x n matrix is diagonalizable when it has n linearly independent eigenvectors. Then A = PDP⁻¹, where the columns of P are eigenvectors and D holds the eigenvalues.
## Why it helps
Powers become easy: Aᵏ = PDᵏP⁻¹, and Dᵏ just raises each diagonal entry to the power k.
## Symmetric matrices
Every real symmetric matrix is diagonalizable with orthogonal eigenvectors, so P can be chosen with P⁻¹ = Pᵀ.
'''),
  ]),
  _C('fin101', 'FIN101', 'Introduction to Finance', [
    _F('fin101-w2', 'Week 2 - Time Value of Money.pdf', 'pdf', 9800, '''
## Why money has time value
A pound today is worth more than a pound next year because it can be invested to earn a return, and because inflation reduces purchasing power.
## Future value
Future value grows a present amount forward: FV = PV x (1 + r)ⁿ, where r is the rate per period and n is the number of periods.
## Present value
Present value discounts a future amount back to today: PV = FV / (1 + r)ⁿ. Higher rates or longer horizons make the present value smaller.
## Real versus nominal returns
The real return is roughly the nominal return minus inflation. A 20 percent return with 25 percent inflation is a real loss.
'''),
    _F('fin101-w3', 'Week 3 - Compound Interest.pptx', 'slides', 8700, '''
## Simple versus compound interest
Simple interest is paid only on the original principal. Compound interest is paid on the principal plus the interest already earned, so growth accelerates over time.
## Compounding frequency
Compounding more often, monthly instead of yearly, increases the effective annual rate: EAR = (1 + r/m)ᵐ - 1.
## The rule of 72
Dividing 72 by the annual interest rate in percent gives the approximate number of years to double an investment.
'''),
  ]),
];
