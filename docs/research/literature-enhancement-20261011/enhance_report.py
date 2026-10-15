from pathlib import Path
from copy import deepcopy
import hashlib
import json
import zipfile
from lxml import etree

ROOT = Path(__file__).resolve().parents[3]
WORK = ROOT / 'build/litqa'
OUT = ROOT / 'deliverables/research/literature-enhancement-20261011'
SOURCE = ROOT / 'deliverables/research/paper-revision-20261011/CACR2026EA16XZ-作品设计报告-论文修订版.docx'
TARGET = OUT / 'CACR2026EA16XZ-作品设计报告-文献增强版.docx'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == '101f19e0675c8020c5d59515743b1973e6ffad04acd1ed5c94281efeaa0b2757'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
      'a': 'http://schemas.openxmlformats.org/drawingml/2006/main'}
W = '{' + NS['w'] + '}'
with zipfile.ZipFile(SOURCE) as source_zip:
    package = {name: source_zip.read(name) for name in source_zip.namelist()}
original_root = etree.fromstring(package['word/document.xml'])
root = deepcopy(original_root)
body = root.find('w:body', NS)
changes = []

def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=NS))

def paragraph(value, style='RWBody'):
    element = etree.Element(W + 'p')
    properties = etree.SubElement(element, W + 'pPr')
    etree.SubElement(properties, W + 'pStyle', {W + 'val': style})
    if style == 'RWCaption':
        etree.SubElement(properties, W + 'keepNext')
    run = etree.SubElement(element, W + 'r')
    etree.SubElement(run, W + 't').text = value
    return element

def insert_before(prefix, items):
    matches = [element for element in body if text(element).startswith(prefix)
               and not element.xpath('./w:pPr/w:pStyle[@w:val="RWTOC1" or @w:val="RWTOC2"]', namespaces=NS)]
    assert len(matches) == 1, (prefix, len(matches))
    anchor = matches[0]
    for value in items:
        element = paragraph(value) if isinstance(value, str) else value
        anchor.addprevious(element)
        changes.append({'before': prefix, 'text': text(element)})

def table(rows):
    element = etree.Element(W + 'tbl')
    properties = etree.SubElement(element, W + 'tblPr')
    etree.SubElement(properties, W + 'tblW', {W + 'w': '9638', W + 'type': 'dxa'})
    etree.SubElement(properties, W + 'tblLayout', {W + 'type': 'fixed'})
    borders = etree.SubElement(properties, W + 'tblBorders')
    for side in ['top', 'left', 'bottom', 'right', 'insideH', 'insideV']:
        etree.SubElement(borders, W + side, {W + 'val': 'single', W + 'sz': '4', W + 'color': '888888'})
    margins = etree.SubElement(properties, W + 'tblCellMar')
    for side in ['top', 'bottom', 'left', 'right']:
        etree.SubElement(margins, W + side, {W + 'w': '75', W + 'type': 'dxa'})
    widths = [1850, 3894, 3894]
    grid = etree.SubElement(element, W + 'tblGrid')
    for width in widths:
        etree.SubElement(grid, W + 'gridCol', {W + 'w': str(width)})
    for row_index, values in enumerate(rows):
        row = etree.SubElement(element, W + 'tr')
        row_properties = etree.SubElement(row, W + 'trPr')
        etree.SubElement(row_properties, W + 'cantSplit')
        if row_index == 0:
            etree.SubElement(row_properties, W + 'tblHeader')
        for width, value in zip(widths, values):
            cell = etree.SubElement(row, W + 'tc')
            properties = etree.SubElement(cell, W + 'tcPr')
            etree.SubElement(properties, W + 'tcW', {W + 'w': str(width), W + 'type': 'dxa'})
            if row_index == 0:
                etree.SubElement(properties, W + 'shd', {W + 'fill': 'EEEEEE'})
            cell_paragraph = paragraph(value, 'RWTable')
            ppr = cell_paragraph.find('w:pPr', NS)
            etree.SubElement(ppr, W + 'spacing', {W + 'after': '0', W + 'before': '0', W + 'line': '280', W + 'lineRule': 'auto'})
            for run in cell_paragraph.findall('w:r', NS):
                rpr = etree.Element(W + 'rPr')
                etree.SubElement(rpr, W + 'rFonts', {W + 'eastAsia': '宋体', W + 'ascii': 'Times New Roman'})
                etree.SubElement(rpr, W + 'sz', {W + 'val': '21'})
                if row_index == 0:
                    etree.SubElement(rpr, W + 'b')
                run.insert(0, rpr)
            cell.append(cell_paragraph)
    return element

insert_before('由上述研究可见', [
'与本作品最直接相关的文献，说明了两种不同的实现风险。KyberSlash研究旧Kyber实现中依赖秘密操作数的除法时延，并在特定Arm平台验证其影响[24]；clangover则说明，编译器可能把源码中的无分支写法重新变成依赖秘密的控制流[6][11]。前者要求检查算术操作与目标处理器，后者要求把编译器和优化选项纳入防护对象。这些历史研究提供审查依据，不能直接证明本作品固定ML-KEM-768程序存在同一问题。',
'频率变化还可能把数据相关功耗映射为可观察时间。Hints from Hertz讨论NTT的此类风险，其Kyber应用对象是去掉压缩与解压缩的CPA版本，另研究CCA安全的NTTRU[25]。因此，该文的安全损失估计不作为完整ML-KEM-768的定量结论。对本作品而言，它支持记录频率条件的必要性，却不能把平均频率反馈合格解释为已经阻断功耗或调频侧信道。',
'标准依据也需要区分算法规范与实现建议。FIPS 203规定ML-KEM算法；2025年9月正式发布的SP 800-227在第3.3节建议采用常数时间实现抵御时序攻击，并强调防护需结合应用暴露面和成本[23]。本作品据此选择本地时间观测与语义保持的实现防护，不把NIST标准化活动表述为专门的时序侧信道竞赛。',
'形式化结果提供了更强但有明确对象的参照。Almeida等在EasyCrypt中证明所研究ML-KEM规范的正确性与随机预言机模型下的IND-CCA安全性，并连接到两份Jasmin实现的功能等价与恒时证明[26]。该结论不能自动覆盖本作品所用C库、封装层和构建产物。本文采用文献约束审查范围、使用实测评价具体配置，避免把他人的证明转记为本作品已取得的保证。'
])
insert_before('实验安排分为三个部分', [
'本题的工程目标是对发现的问题实施防护，并在相同或等价条件下复测，同时核验功能和性能；第三方库中已有公开来源的问题也可以成为研究对象，无须将问题首次发现作为前提。但问题必须对应实际版本、启用路径和明确的修复。本文已有防护结果来自有来源的人工机制对照，尚不能改称当前上游库原生缺陷的发现与修复；统计复算效率的改进另行评价，不替代这一防护闭环。'
])
insert_before('独立向量测试与差分检查', [
'FIPS 203第6.3节将重加密比较得到的隐式拒绝标志列为秘密中间数据，禁止以任何形式将其作为输出，并要求在内部解封装结束前销毁[1]。隐式拒绝因而不仅是“始终返回一段密钥”，还要求保留重加密验证、按密文与拒绝秘密导出替代密钥，并避免额外暴露内部判定。外部长度错误可在封装层拒绝；不能把这种公开接口检查与内核对正确长度无效密文的处理混为一谈。'
])
insert_before('4.4　置换检验', [
'这里的“掩码选择”是通过位运算选择候选值，区别于把秘密拆分为随机份额的侧信道掩码。前者针对控制流，后者主要改变中间数据的泄露表示，两者的成本和验证要求不同。本文已有结果不包含随机份额掩码、功耗或电磁抗性实验，也不把位掩码实现称为具有高阶掩码安全性。',
'防护选择应与泄露机制相对应，并保持原算法功能。Ravi等给出了两类特定低成本检测式防御失效的案例[27]；这不能推出所有异常检测均无效，却说明仅靠识别“可疑输入”不足以代替实现防护。若检测后的中止或密钥丢弃改变题目要求的隐式拒绝行为，该具体方案就不适合作为本作品的内核修复。',
paragraph('表4.2　防护措施、适用条件与本作品证据', 'RWCaption'),
table([
['措施', '机制与采用条件', '本作品已有证据与限制'],
['位掩码选择与值屏障', '减少秘密相关分支；保留输出语义，核对实际工具链。[6][11]', '已有历史同机对照；固定上游已包含相关保护，不能重复认领为新修复。'],
['全长比较与拒绝选择', '保留重加密、完整比较及替代密钥导出，不提前泄露判定。[1]', '固定版本已采用相应路径；功能与源码证据不替代全路径恒时证明。'],
['随机份额掩码与乱序', '需另行论证随机性、份额转换和组合后的泄露模型。', '未实现、未测功耗或电磁；不列为本作品已验证防护。'],
['CPU分区与频率窗口', '降低或记录测量扰动，说明调度与频率条件。[25]', '已有环境控制与恢复记录；属于测量控制，不能视为密码泄露消除。'],
['NTT分块或预计算', '首先是计算组织方式；防护价值需单独建立秘密独立性证据。', '未取得适用的防护证明与实测，不按名称列为已有效。'],
['检测后中止、随机延迟', '前者须核查是否改变拒绝语义；后者不能消除根本依赖。[27]', '不以丢弃替代密钥、休眠、空转或随机等待实现本作品防护。']
]),
'对实际第三方库的修复，应分别回答：缺陷是否存在于采用的快照和配置；改动是否消除了目标秘密依赖；修改后是否仍保持ML-KEM功能；同环境下的时间差异与性能代价如何。若固定版本已经包含上游修复，合理结论是核验防护的适用性，而不是制造缺陷再把它报告为上游原生问题。这个区别决定了历史机制实验与当前部署审查各自能够承担的论证。'
])
insert_before('这一比较仍有两项重要限制', [
'防护效果还需要与代价一起解释。在本轮五类输入等权总均值口径下，五个种子中的掩码对照比参考实现慢187—322 ns，比人工分支对照快714—1208 ns，比正常优化对照慢99—361 ns。由此可见，对本人工机制采用位掩码选择并未带来必然的净减速；但与已经采用保护的参考实现比较仍有小幅开销。该结果对应同机、同构建的完整解封装成本，不是新旧裸金属测量之间的加速比，也不是任意输入下的开销上界。'
])
insert_before('在统计解释上，平均时间差', [
'补充实验应优先补齐“实际第三方问题—语义保持修复—同条件复测”的证据。表6.2列出下一轮设计；它们尚未执行，也不计入第5章的已完成结果。首先核查固定版本中仍适用的已知问题和实际构建条件；没有确认缺陷时不生成修复效果数据，也不为增加样本量重复现有六进程测试。',
paragraph('表6.2　面向实际第三方实现的补充验证设计（未执行）', 'RWCaption'),
table([
['研究问题', '对照设计与输出', '结论成立的条件'],
['已知问题是否适用', '固定来源、完整提交、启用后端与正式产物；核对公开修复和采用路径。', '区分仍适用、已修复、不启用、证据不足；单凭论文题名不能确认。'],
['修复是否保持语义', '在确认问题后作最小补丁；以独立公开向量、接口边界及隐式拒绝输出核验。', '不得移除重加密、固定拒绝密钥或泄露验证标志；普通与动态检查分开。'],
['修复效果及代价', '同机、同工具链下比较修复前后；同时报告时间分布、功能结果与开销。', '预先限定输入、样本单位、运行顺序和停止条件；保留失败与全部长尾。'],
['工具链下能否保持', '在已选的构建配置中核对产物与功能，逐配置记录，不合并不同环境。', '只对实际核验配置作结论；机器码检查不代替微架构模型或统计依据。']
]),
'若增加dudect式Welch检验或TVLA式分析，应把它们作为特定分组下的差异筛查，事先固定样本预算、查看结果的时点及多重比较处理[3][4]。同一进程的连续调用不能仅因数量大就视为独立重复，公开输入类别的时间差也不自动等于秘密泄露。以“未显著”为停止条件反复补采，会改变错误率；未检出结果仍需结合效应量与有依据的检出能力解释，不能替代恒时证明。'
])
insert_before('本作品将功能验证、实现检查和统计分析', [
'文献与现有实现的对照进一步限定了作品的防护贡献：位掩码对照用于验证一个明确的历史机制，第三方库审查用于确认现有保护的适用范围，环境测量用于解释观测条件。三者共同服务于题目的检测、定位、防护与复测，但不能相互替代。针对当前库原生问题的新增修复，仍须以实际适用性和修复前后证据为基础。'
])
references = [
'[23] Alagic G, Barker E, Chen L, et al. Recommendations for Key-Encapsulation Mechanisms. NIST SP 800-227, 2025-09，正式版，第3.3节. DOI:10.6028/NIST.SP.800-227.',
'[24] Bernstein D J, Bhargavan K, Bhasin S, et al. KyberSlash: Exploiting secret-dependent division timings in Kyber implementations. IACR Transactions on Cryptographic Hardware and Embedded Systems, 2025(2):209–234. DOI:10.46586/tches.v2025.i2.209-234.',
'[25] Yu T, Cheng C, Yang Z, et al. Hints from Hertz: Dynamic Frequency Scaling Side-Channel Analysis of Number Theoretic Transform in Lattice-Based KEMs. Cryptology ePrint Archive, 2024/070，2024-06-10修订版. https://eprint.iacr.org/2024/070 .',
'[26] Almeida J B, Arranz Olmos S, Barbosa M, et al. Formally verifying Kyber Episode V: Machine-checked IND-CCA security and correctness of ML-KEM in EasyCrypt. Cryptology ePrint Archive, 2024/843，CRYPTO 2024论文的修订稿. https://eprint.iacr.org/2024/843 .',
'[27] Ravi P, Paiva T, Jap D, D’Anvers J P, Bhasin S. Defeating Low-Cost Countermeasures against Side-Channel Attacks in Lattice-based Encryption: A Case Study on Crystals-Kyber. IACR Transactions on Cryptographic Hardware and Embedded Systems, 2024(2):795–818. DOI:10.46586/tches.v2024.i2.795-818.'
]
last_reference = next(e for e in body if text(e).startswith('[22]'))
for value in references:
    element = paragraph(value)
    last_reference.addnext(element)
    last_reference = element
    changes.append({'reference': value})
package['word/document.xml'] = etree.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True)
OUT.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(TARGET, 'w', compression=zipfile.ZIP_DEFLATED) as output_zip:
    for name, payload in package.items():
        output_zip.writestr(name, payload)
manifest = {'source': str(SOURCE.relative_to(ROOT)), 'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
            'output': str(TARGET.relative_to(ROOT)), 'insertions': changes,
            'new_experiments': 0, 'new_remote_operations': 0}
(Path(__file__).parent / 'edit-log.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
(WORK / 'candidate-text.txt').write_text('\n'.join(text(e) for e in body))
print(json.dumps({'insertions': len(changes), 'source_sha256': manifest['source_sha256'], 'output': str(TARGET)}, ensure_ascii=False))
