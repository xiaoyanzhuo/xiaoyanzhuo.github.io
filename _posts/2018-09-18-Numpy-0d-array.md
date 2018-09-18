---
layout: article
title: Numpy - How to best deal with possible 0d arrays
key: 10005
tags:
- Python
- Python Tricks
- numpy
---

## Description:

You may got ***"iteration over a 0-d array"*** error, when looping a numpy array. This is because the numpy array only have one element.

eg.

```python
import numpy as np

a = 1
a = np.asarray(a)
for i in a:
  print(i)
```

```python
TypeError: iteration over a 0-d array
```

<!--more-->

when you using ***zip()*** in this condition, you will get a similar problem.

eg.

```python
import numpy as np

a, b = 1, 2
a, b = np.asarray(a), np.asarray(b)
for i, j in zip(a, b):
  print(i+j)
```

```python
TypeError: zip argument #1 must support iteration
```

## Solution:

apply ***numpy.atleast_1d()*** on your numpy array. For previous example, you can just replace ***asarray()*** with ***atleast_1d()***.

```python
import numpy as np

a, b = 1, 2
a, b = np.atleast_1d(a), np.atleast_1d(b)
for i, j in zip(a, b):
  print(i+j)
```

You can find more discussion in [Python, numpy; How to best deal with possible 0d arrays](https://stackoverflow.com/questions/35617073/python-numpy-how-to-best-deal-with-possible-0d-arrays).
