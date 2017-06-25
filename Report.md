# Report

## 小组成员

* 计42 王栋 2014011290
* 计42 王倩

## 组内分工

* 王栋：预处理、第三题、第四题
* 王倩：第二题

## 重要事项

* 由于我们小组开始时使用R语言进行编程，在大规模数据集时，R语言的大部分分类方法不支持稀疏矩阵，故而无法生成有效的模型与结果。
* 后来我们选择了Python语言进行编程，而由于选择python时已经临近deadline，故而也没有时间跑完详细的测试结果

## 数据预处理理与特征提取(R语言完成)

* 通过project1写好的预处理程序可以提取出50000篇文章的full_text和classify，提取结果保存在‘/precondition/dataframe.csv’中，
* 由于有的新闻具有多个分类，而对于此类新闻无论是将其拆分成多条新闻，还是随机取一个类别作为其分类，在这里都是不合适的，故而我们在之后的算法中全部采用二分类的策略
* 由于R语言对于文本分类的处理效果很差，导致生成的tf-idf的feature十分多(我们生成了50w+的feature)，故而在编程过程中我们放弃了R语言而使用Python来实现(10w左右)

> 需要的R包

```
XML、tm、NLP
```

> 主要代码所在文件

```
preconditioning.R
```

## 基本分类器器运用用与比比较

* 我们首先分析了二分类与多分类的不同。多分类操作便捷，但只能得到一个预测值。二分类可以得到多个预测值，但需要多个分类器。为了更好地比较各种分类方法的效果，本题我们都采用了二分类的方法。
* 特征提取发现如果将所有classifier的内容都算入，则又五千多个类别，经过一些筛选（出现频率过于平均的会被去掉，因为它对每个文章都差不多）也仍然有3千多，形成的target矩阵太大。因此我们采用了第一次作业的标准提取分类。
* 我们用表格记录了所有分类器每一轮的时间和三个衡量标准(见2.csv)，并进行分析，分析发现：速度：naive_bayes>svm>Logistic Regression>Decision Tree>MLP


## ensemble 算法运用用与比比较

* 在R提供的包中，只有Gradient Boost（xgboost）支持稀疏矩阵，而在python（sklearn）中除了Gradient Boost的predict都支持稀疏矩阵，故开始时我们用R语言实现ensemble算法相当困难

* 每种算法测试的三种指标以及时间存储在/result文件夹下，以Arts为例

| Algorithm      | Precision |  Recall | F1-measure | Time     |
| -------------- | :-------: | ------: | ---------- | -------- |
| Bootstrap      |  0.78889  | 0.60610 | 0.68552    | 60.20278 |
| AdaBoost       |  0.78385  | 0.73415 | 0.75819    | 84.27985 |
| Random Forest  |  0.89640  | 0.48537 | 0.62975    | 15.33956 |
| Gradient Boost |  0.80995  | 0.77439 | 0.79177    | 75.95636 |

* 根据在‘Arts’分类下的二分类，可以看出，```random Forest``` 的速度与准确度都很高，但是其随机性较大，召回率很低，故而其综合评价最低。而AdaBoost与GradientBoost的综合评价都不错，但是其消耗时间会更长。Bootstrap没有什么明显的优点与缺点。所以，选择算法时需要根据需求来选择，是速度快的还是更准确的，还是召回率高的。

>用R实现需要的包

```
adabag、xgboost、randomForest、Matrix
```
> 用Python实现需要的包

```
sklearn、pandas、nltk
```

* 其中nltk需要继续安装```punkt``` 和```stopwords```
* 可通过```python nltk_download.py``` 打开安装界面
* 也可以直接在Python中运行如下指令打开nltk包的下载安装界面

```
import nltk
nltk.download()
```

> 主要代码所在文件

```
textpre.py 包含文本处理以及计算tf-idf的整个过程
adaboost.py/bootstrap.py/randomforest.py/gradientboost.py 包含四种算法的实现
ensemble.py 是对于四种算法的整合，生成训练集和验证集后同意测试四种算法，避免集合的不同对算法效率的影响
```

## 聚类算法运用用与比比较

