from copy import deepcopy
from pathlib import Path
import hashlib
import json
import zipfile

from lxml import etree


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
ORIGINAL = REPO / 'deliverables/research/aris-report-g2-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx'
BASE = WORK / 'base-49-page-20261010.docx'
OUTPUT = WORK / 'CACR2026EA16XZ-作品设计报告-四项研究整合候选版.docx'
EXPECTED = '96e2de8af1238518f8d754cd9f969a4e82499d8b89552e143128aeba8da861e6'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'w14': 'http://schemas.microsoft.com/office/word/2010/wordml',
      'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math'}


def sha(value):
    return hashlib.sha256(value).hexdigest()


def xml_hash(element):
    return sha(etree.tostring(element))


def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=NS))


def tag(prefix, name):
    return '{' + NS[prefix] + '}' + name


def mr(value, plain=False):
    run = etree.Element(tag('m', 'r'))
    if plain:
        etree.SubElement(etree.SubElement(run, tag('m', 'rPr')), tag('m', 'sty')).set(tag('m', 'val'), 'p')
    etree.SubElement(run, tag('m', 't')).text = value
    return run


def children(parent, values):
    for value in values:
        parent.append(mr(value) if isinstance(value, str) else value)
    return parent


def script(base, sub=None, sup=None):
    name = 'sSubSup' if sub is not None and sup is not None else ('sSub' if sub is not None else 'sSup')
    item = etree.Element(tag('m', name))
    children(etree.SubElement(item, tag('m', 'e')), [base])
    if sub is not None:
        children(etree.SubElement(item, tag('m', 'sub')), [sub])
    if sup is not None:
        children(etree.SubElement(item, tag('m', 'sup')), [sup])
    return item


def frac(num, den):
    item = etree.Element(tag('m', 'f'))
    children(etree.SubElement(item, tag('m', 'num')), num)
    children(etree.SubElement(item, tag('m', 'den')), den)
    return item


def root(values):
    item = etree.Element(tag('m', 'rad'))
    etree.SubElement(etree.SubElement(item, tag('m', 'radPr')), tag('m', 'degHide')).set(tag('m', 'val'), '1')
    etree.SubElement(item, tag('m', 'deg'))
    children(etree.SubElement(item, tag('m', 'e')), values)
    return item


def accent(value, char):
    item = etree.Element(tag('m', 'acc'))
    etree.SubElement(etree.SubElement(item, tag('m', 'accPr')), tag('m', 'chr')).set(tag('m', 'val'), char)
    children(etree.SubElement(item, tag('m', 'e')), [value])
    return item


def delim(values, begin='[', end=']'):
    item = etree.Element(tag('m', 'd'))
    prop = etree.SubElement(item, tag('m', 'dPr'))
    etree.SubElement(prop, tag('m', 'begChr')).set(tag('m', 'val'), begin)
    etree.SubElement(prop, tag('m', 'endChr')).set(tag('m', 'val'), end)
    children(etree.SubElement(item, tag('m', 'e')), values)
    return item


def main():
    assert sha(ORIGINAL.read_bytes()) == EXPECTED
    assert not OUTPUT.exists(), 'fresh attempt required; retain failed candidate separately'
    BASE.write_bytes(ORIGINAL.read_bytes())
    edits = []
    with zipfile.ZipFile(BASE) as source:
        document = etree.fromstring(source.read('word/document.xml'))
        body = document.find('w:body', NS)
        old = list(body)
        old_hashes = [xml_hash(e) for e in old]
        old_tables = document.findall('.//w:tbl', NS)
        old_features = {k: [xml_hash(e) for e in document.findall(p, NS)] for k, p in {
            'math': './/m:oMath', 'drawings': './/w:drawing', 'sections': './/w:sectPr'}.items()}
        changed = set()
        ids = set(document.xpath('.//w:p/@w14:paraId', namespaces=NS))
        next_id = 0xCA170001

        def plain(value, template, keep_id=False):
            nonlocal next_id
            p = deepcopy(template)
            rp = p.find('w:r/w:rPr', NS)
            rp = deepcopy(rp) if rp is not None else None
            for child in list(p):
                if child.tag != tag('w', 'pPr'):
                    p.remove(child)
            if not keep_id:
                while f'{next_id:08X}' in ids:
                    next_id += 1
                p.set(tag('w14', 'paraId'), f'{next_id:08X}')
                ids.add(f'{next_id:08X}')
                next_id += 1
                p.attrib.pop(tag('w14', 'textId'), None)
            run = etree.SubElement(p, tag('w', 'r'))
            if rp is not None:
                run.append(rp)
            node = etree.SubElement(run, tag('w', 't'))
            node.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
            node.text = value
            return p

        def replace(index, value, slot):
            assert old[index].tag == tag('w', 'p')
            assert not old[index].findall('.//m:oMath', NS) and not old[index].findall('.//w:drawing', NS)
            new = plain(value, old[index], True)
            body.replace(old[index], new)
            changed.add(index)
            edits.append({'slot': slot, 'base_body_index': index, 'before': text(old[index]),
                          'after': value, 'old_xml_sha256': old_hashes[index], 'new_xml_sha256': xml_hash(new)})
            return new

        body_template = old[398]
        caption_template = old[377]
        section_template = old[357]
        formula_template = old[374]
        assert text(formula_template) == '(5-5)'

        def add(anchor, value, slot, template=None):
            p = plain(value, template if template is not None else body_template)
            anchor.addprevious(p)
            edits.append({'slot': slot, 'added': value, 'paragraph_id': p.get(tag('w14', 'paraId'))})
            return p

        def equation(anchor, nodes, label, slot):
            p = plain('', formula_template)
            for c in list(p):
                if c.tag != tag('w', 'pPr'):
                    p.remove(c)
            etree.SubElement(etree.SubElement(p, tag('w', 'r')), tag('w', 'tab'))
            math = etree.SubElement(p, tag('m', 'oMath'))
            children(math, nodes)
            run = deepcopy(formula_template.findall('w:r', NS)[-1])
            run.find('w:t', NS).text = label
            p.append(run)
            anchor.addprevious(p)
            edits.append({'slot': slot, 'label': label, 'native_omml': True,
                          'math_text': ''.join(math.xpath('.//m:t/text()', namespaces=NS)),
                          'paragraph_id': p.get(tag('w14', 'paraId'))})

        def table(anchor, label, headers, data, widths):
            cap = add(anchor, label, label + '_caption', caption_template)
            ppr = cap.find('w:pPr', NS)
            if ppr.find('w:keepNext', NS) is None:
                etree.SubElement(ppr, tag('w', 'keepNext'))
            t = deepcopy(old_tables[7])
            assert sum(widths) == 8957
            for row in list(t.findall('w:tr', NS)):
                t.remove(row)
            grid = t.find('w:tblGrid', NS)
            for c in list(grid):
                grid.remove(c)
            for width in widths:
                etree.SubElement(grid, tag('w', 'gridCol')).set(tag('w', 'w'), str(width))
            rows = old_tables[7].findall('w:tr', NS)
            for row_index, values in enumerate([headers] + data):
                template = rows[0] if row_index == 0 else (rows[-1] if row_index == len(data) else rows[1])
                row = deepcopy(template)
                cells = template.findall('w:tc', NS)
                for cell in list(row.findall('w:tc', NS)):
                    row.remove(cell)
                prop = row.find('w:trPr', NS)
                prop.find('w:trHeight', NS).set(tag('w', 'hRule'), 'atLeast')
                if prop.find('w:cantSplit', NS) is None:
                    etree.SubElement(prop, tag('w', 'cantSplit'))
                for c in list(prop.findall('w:tblHeader', NS)):
                    prop.remove(c)
                if row_index == 0:
                    etree.SubElement(prop, tag('w', 'tblHeader')).set(tag('w', 'val'), '1')
                for column, value in enumerate(values):
                    cell = deepcopy(cells[min(column, len(cells) - 1)])
                    cell.find('w:tcPr/w:tcW', NS).set(tag('w', 'w'), str(widths[column]))
                    old_p = cell.find('w:p', NS)
                    p = plain(str(value), old_p)
                    if row_index > 0:
                        for c in list(p.find('w:pPr', NS).findall('w:keepNext', NS)):
                            p.find('w:pPr', NS).remove(c)
                    for c in list(cell.findall('w:p', NS)):
                        cell.remove(c)
                    cell.append(p)
                    row.append(cell)
                t.append(row)
            anchor.addprevious(t)
            edits.append({'slot': label, 'headers': headers, 'data': data, 'widths_twips': widths,
                          'xml_sha256': xml_hash(t)})

        outline = json.loads((WORK / 'outline-review.json').read_text())
        for slot in outline['stale_and_scope_changes']:
            index = slot['baseline_body_index_zero_based']
            if index not in [90, 98, 131, 153, 185, 200, 249, 274, 415, 416, 422, 423]:
                continue
            assert text(old[index]) == slot['old_exact_text']
            value = slot['suggested_text']
            if slot['action'] == 'append':
                value = text(old[index]) + value
            if index == 423:
                value = value.replace('更强的逐调用恒频或真实总体误报/检出不自行追加为官方硬门。', '')
            replace(index, value, slot['location'])

        abstract = old_tables[0].xpath('.//w:p[@w14:paraId="CA140001"]', namespaces=NS)[0]
        abstract_before = text(abstract)
        abstract_after = (
            '本作品面向ML-KEM解封装实现的本地审计需求，设计并实现C11审计与精确复算系统。'
            '系统采用固定ML-KEM-768便携实现，以独立公开向量及接口检查验证功能，记录完整解封装逐次时间，'
            '并关联源码、产物、环境和成本。将数据资格与统计数值分开输出，支持有界成对数据的整数精确复算。'
            '八个固定任务与SciPy尾计数及判定一致；预导入流程对照、同语言函数对照及干净重建均支持固定任务的效率改进。'
            '有限模型与后赋标签结果通过独立核对；同机人工机制掩码在五个种子的原名义检验里均未再检出。'
            'G2保存126528次完整调用，200个反馈窗口通过工程规则、纯主几何覆盖99.4948%。'
            '后续分别补入旧原值耗时描述、新RAW空窗三进程及同公开输入、同产物六进程完整调用，保留全部长尾和时间账。'
            '原学生化均值区间的条件有限覆盖下界已推导，但不能认证现有4—20单位。'
            '作品已完成封存包新目录复算，支持本地审查与离线复核；观察范围、精度和统计保证分别解释，'
            '不外推为全库恒时。R02/R04仍部分签收。')
        abstract.getparent().replace(abstract, plain(abstract_after, abstract, True))
        changed.add(24)
        edits.append({'slot': 'abstract', 'base_body_index': 24, 'before': abstract_before, 'after': abstract_after})

        old_45 = text(old[257])
        new_46 = old_45.replace('4.5', '4.6', 1)
        renamed_46 = replace(257, new_46, 'old_4.5_to_4.6')
        label = old[259].findall('w:r/w:t', NS)
        assert len(label) == 1 and label[0].text == '(4-4)'
        label[0].text = '(4-9)'
        changed.add(259)
        edits.append({'slot': 'old_equation_4-4_to_4-9', 'base_body_index': 259,
                      'before': '(4-4)', 'after': '(4-9)', 'math_unchanged': True})
        bookmarks = document.xpath('.//w:bookmarkStart/@w:id', namespaces=NS)
        bookmark_id = max(map(int, bookmarks)) + 1
        toc_template = next(p for p in body.findall('w:p', NS)
                            if p.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS) == ['RWTOC2'])

        def new_section(anchor, heading, name, toc_after):
            nonlocal bookmark_id
            start = etree.Element(tag('w', 'bookmarkStart'))
            start.set(tag('w', 'id'), str(bookmark_id))
            start.set(tag('w', 'name'), name)
            anchor.addprevious(start)
            add(anchor, heading, heading + '_heading', section_template)
            end = etree.Element(tag('w', 'bookmarkEnd'))
            end.set(tag('w', 'id'), str(bookmark_id))
            bookmark_id += 1
            toc = deepcopy(toc_template)
            toc.set(tag('w14', 'paraId'), f'{0xCA17F000 + bookmark_id:08X}')
            toc.find('w:hyperlink', NS).set(tag('w', 'anchor'), name)
            values = toc.findall('.//w:t', NS)
            assert len(values) == 2
            values[0].text, values[1].text = heading, '1'
            toc_after.addnext(toc)
            edits.append({'slot': 'new_toc', 'heading': heading, 'bookmark': name})
            return end

        toc_old_45 = next(p for p in body.findall('w:p', NS) if text(p).startswith(old_45))
        toc_old_45.findall('.//w:t', NS)[0].text = new_46
        changed.add(old.index(toc_old_45))
        toc_preceding = toc_old_45.getprevious()
        section_start = renamed_46.getprevious()
        assert section_start.tag == tag('w', 'bookmarkStart')
        theory_end = new_section(section_start, '4.5　原均值区间的有限样本覆盖边界',
                                 'rw_heading_finite_20261010', toc_preceding)
        def th(value):
            add(section_start, value, '4.5_body')
        def eq(nodes, label):
            equation(section_start, nodes, label, '4.5_formula')

        th('保持登记单位的原平均效应与学生化区间。事前固定U≥2和有限潜在数组，'
           '独立等概率AB/BA赋值以相互独立的Rademacher符号R表示；一致性、无赋值相关携带及跨单位干扰等现实条件，'
           '须足以支持下列表示。概率仅对赋值计算，不要求时段内调用独立，也不把调用数当作U：')
        eq([script('D', 'j'), '=', script('θ', 'j'), '+', script('R', 'j'), script('γ', 'j'),
            ',   θ=', frac(['Σ', script('θ', 'j')], ['U']), ',   ', accent('θ', '̂'), '=', accent('D', '̄')], '(4-4)')
        eq([accent('V', '̂'), '=', frac(['Σ', script(delim([script('D', 'j'), '−', accent('D', '̄')], '(', ')'), sup='2')],
            ['U(U−1)']), ',   I=', delim([accent('θ', '̂'), '−z', root([accent('V', '̂')]), ', ',
            accent('θ', '̂'), '+z', root([accent('V', '̂')])])], '(4-5)')
        th('所有求和均遍历j=1至U。z>0在观察前固定，I包含端点，标准误为零时仍按原闭区间解释。'
           '令G为各γ平方之和；G>0时，η为最大γ平方占G的比例。η度量未观测反事实主导程度，'
           '不是单次观测最大差。对确定的0<ε<1，定义：')
        eq([script('a', 'ε', '(0)'), '=z', root([frac(['U(1−ε)'], ['U−1+', script('z', sup='2')])])], '(4-6)')
        eq([script('p', '0'), '(ε,η)=min', delim(['1, ', frac(['η'], [script('ε', sup='2')]),
            ', exp', delim(['−', frac([script('ε', sup='2')], ['2η'])])], '{', '}')], '(4-7)')
        eq(['Pr{θ∈I}≥', script(delim(['2Φ(', script('a', 'ε', '(0)'), ')−1−2', root(['η']),
            '−', script('p', '0'), '(ε,η)']), sub='+')], '(4-8)')
        th('其中Φ为标准正态分布函数，方括号下标“+”表示与零取最大值。式（4-8）对任意效应异质程度有效，'
           '固定采用保守Berry–Esseen常数1，依据Tyurin固定v1的一般独立结果[16]，不把同分布常数用于不等权符号。'
           '推导先展开原中心平方和、精确移项覆盖事件，再控制负向方差扰动；对加权独立符号应用正态近似，'
           '以CDF左极限保留离散端点，最后用事件包含与并集界组合。两个共享符号事件没有被假定独立；完整代数另存技术资料。')
        th('G=0时估计量恰等目标，原区间必覆盖，不定义η。G>0时虽有1/U≤η≤1，却不能用下界1/U代替所需上界；'
           '若只有普遍上界1，式（4-8）给出零这个无信息下界，并不表示实际覆盖为零。'
           '原无主导条件下的渐近路线因此获得定量补充，但现有4—20单位仍未由该界获得名义覆盖保证。'
           '独立赋值、可信η上界及无携带/干扰不是文件资格能认证的事实。可信反事实幅度上界可支持另一条有限覆盖路线[14]，'
           '但不能由观测最大值或超时替代。此理论补充尚未作为现有CLI的均值保证实现。')
        section_start.addprevious(theory_end)

        g2_end = old[384].getnext()
        assert g2_end.tag == tag('w', 'bookmarkEnd')
        add(g2_end, '对同一次G2原件补做离线C11耗时描述，没有新增硬件采集。'
            '全部126528次包含预热25280次与主阶段101248次；表5.12保留长尾。各分位沿用式（2-9）的固定下标，'
            '偶数样本取上中位数，MAD不缩放；四个等调用数段和八输入循环不构成新增独立运行。', '5.9_duration_intro')
        table(g2_end, '表5.12　原G2完整调用耗时描述',
              ['阶段', '调用数', 'P50/ns', 'P90/ns', 'P99/ns', '最大/ns', 'MAD/ns'],
              [['预热', 25280, 39314, 39865, 42099, 61005, 130],
               ['主阶段', 101248, 39274, 39844, 41498, 82996, 90]], [1397] + [1260] * 6)
        add(g2_end, '主均值的精确值为3993729753/101248 ns。完整调用窗口总和与首间隙、相邻间隙总和、尾间隙，'
            '按顺序构成主墙钟的整数账：', '5.9_wall_intro')
        equation(g2_end, [mr('4002203951=3993729753+60+8460192+13946 ns', True)], '(5-7)', '5.9_wall_equation')
        add(g2_end, '式（5-7）不是APERF支持区间的几何分解。窗外时间不等于频率未知部分；'
            '主P99与最大值说明平均窗口规则通过时仍存在长尾，不能确定瞬时频率或成因。完整54行描述及原件绑定另存。', '5.9_wall_boundary')

        chapter5_end = g2_end.getnext()
        assert chapter5_end.tag == tag('w', 'bookmarkEnd')
        toc_g2 = next(p for p in body.findall('w:p', NS) if text(p).startswith('5.9　') and p.find('w:hyperlink', NS) is not None)
        measurement_end = new_section(chapter5_end, '5.10　RAW空窗与完整调用的有限运行间描述',
                                       'rw_heading_repeatability_20261010', toc_g2)
        def me(value):
            add(chapter5_end, value, '5.10_body')
        me('后续两项研究使用Ryzen 9 9950X裸金属、Ubuntu 24.04.4、Linux 6.17.0-35-generic/x86_64与GCC 13.3.0，'
           '普通-O2 -g -DNDEBUG产物不含sanitizer。仅设置各自CPU2亲和性并禁用转储，没有root、MSR、调频或独占操作。'
           '两项各自绑定新源码、普通ELF、元数据和原值；CLOCK_MONOTONIC_RAW、clocksource=tsc及声明分辨率1 ns均实际记录。'
           '它们不同于第5.9节的输入、预热与资源条件，不将约30.7 μs和39.3 μs作算法加速比较。')
        me('空窗研究连续执行三个新进程，各1000次预热及100000次主pair；总303000个空pair、606000次采样读钟，密码调用为零。'
           '两次读取timespec后才换算；pair内、相邻pair间及组合间隔分别描述，它们共享读钟序列。表5.13列主pair内分布，三进程零值均为0。')
        table(chapter5_end, '表5.13　RAW主阶段空pair内增量',
              ['进程', '最小/ns', 'P50/ns', 'P90/ns', 'P99/ns', '最大/ns', 'MAD/ns'],
              [['RAW-1', 10, 20, 20, 21, 2004, 0], ['RAW-2', 10, 20, 20, 21, 1603, 0],
               ['RAW-3', 10, 20, 20, 21, 501, 0]], [1397] + [1260] * 6)
        me('声明1 ns、最小正观察10 ns和主空窗P50/P99为20/21 ns属于不同量。空窗增量不是两次API调用的完整总成本；'
           'MAD为零不意味着零误差。新结果不倒校准旧G2，也不从任何完整调用减去20 ns。'
           '普通与动态软件检查各2/2通过，动态产物未参与实际采样；全部18行C描述与180个统计量由独立整数复核一致。')
        me('完整调用研究固定单个公开NIST ML-KEM-768验收用例tgId=5、tcId=86。两次新连接批次各三个顺序进程，共用普通ELF与同一启动期。'
           '每进程先作一次设置调用，再计时预热25000次、主阶段25000次；完整封装检查及原生内核均在窗口内，'
           '32字节输出在第二次读钟后与外部预期核对，再消费和擦除，分配与I/O在窗外。实际普通ELF调用顺序另经反汇编核对。')
        table(chapter5_end, '表5.14　固定公开输入的六进程主阶段完整调用',
              ['批次/进程', 'P50/ns', 'P90/ns', 'P99/ns', '最大/ns', 'MAD/ns'],
              [['E1-P1', 30678, 30728, 32020, 56266, 21], ['E1-P2', 30718, 30758, 32070, 52839, 21],
               ['E1-P3', 30707, 30757, 32000, 44915, 30], ['E2-P1', 30678, 30737, 32010, 53951, 30],
               ['E2-P2', 30678, 30727, 32000, 59922, 30], ['E2-P3', 30687, 30728, 32020, 43862, 29]],
              [1657] + [1460] * 5)
        me('表5.14每行25000次，六个主P50观察范围40 ns、主P99范围70 ns；这是有限观察范围，不是误差界、等价界或检出能力。'
           '全部300000次计时中预热与主各150000次，均保留；预热最大值达68449 ns。'
           '六次设置及Linux软件资格另计，Linux完整算法入口总账300138次，包括300030次解封装、54次密钥生成和54次封装，'
           '不把全部入口称为计时解封装。普通与ASan/UBSan资格各5/5通过；第二批复用产物，不重建或重跑资格，未认证LSan。')
        me('完整36行C描述、360个统计量、六份摘要及各阶段整数账由独立算术复核一致。'
           '阶段墙钟等于pair内与pair间总和，也等于组合增量之和；预热至主阶段边界另保留。'
           '两连接批次采样边界间隔约346.446秒，取同启动期RAW值，不是纯认证耗时、CPU空闲或跨环境重复。'
           '可见频率文件前后相同只是快照，不能证明全程恒频。两个连接、六进程及300000条记录均不自动构成独立同分布总体样本或长期稳定性。')
        me('数值、实物和主张分别内部复核，审阅范围各自记录，不称外部同行评审。'
           '初次复用连接认证拒绝发生在采集前，之后按密码重新认证；失败保留，不增加采集进程。'
           '计数副记录的勘误保留修改前字节，未改原始数据或归档。结束后原进程与自有组均已回收、连接关闭。'
           '这两项研究补充有限测量描述，不新增类别检测、防护效果或真实总体错误率保证；R02/R04仍部分签收。')
        chapter5_end.addprevious(measurement_end)

        add(old[399], '新增测量把接口声明、空窗分布与完整负载运行间范围分别保存；有限样本推导则把均值区间的保证损失显式化。'
            '这些增量使能力边界能够具体检查，但不将材料合格、数值一致或较小观察范围直接升级为统计有效性。', '6.2_progress')
        add(old[443], '[16] Tyurin I. New estimates of the convergence rate in the Lyapunov theorem. '
            'arXiv:0912.0726v1, 2009. https://arxiv.org/abs/0912.0726v1 . '
            '研究预印本；本文使用一般独立结果所允许的保守常数1，定向核查式(1)与定理7，未重现计算证书。', 'reference_16', old[442])

        index_table = old[448]
        for values in [
            ['G2-T', 'docs/evidence/g2-timing-description-20261010', '表5.12；式5-7；54行原值描述'],
            ['W-F', 'docs/research/aris-weak-mean-finite-20261010', '第4.5节；原区间有限下界与解析复核'],
            ['RAW-C', 'docs/evidence/raw-clock-20261010', '表5.13；303000空pair及18行描述'],
            ['REP-6', 'docs/evidence/ordinary-repeatability-20261010', '表5.14；两批六进程及36行描述'],
        ]:
            row = deepcopy(index_table.findall('w:tr', NS)[-1])
            for cell, value in zip(row.findall('w:tc', NS), values):
                p = cell.find('w:p', NS)
                new = plain(value, p)
                for c in list(cell.findall('w:p', NS)):
                    cell.remove(c)
                cell.append(new)
            index_table.append(row)
        changed.add(448)
        edits.append({'slot': 'appendix_A_four_rows', 'base_body_index': 448, 'original_rows_preserved': True})
        add(old[470], '四项后续研究各有独立来源及清单，不改写原49页报告与925项G2补充件的身份。'
            'G2-T仅对既有原值离线分析；W-F为原区间的理论资料；RAW-C与REP-6分别描述新空窗口和固定公开输入完整调用。'
            '各自的完整原值、C输出、失败记录、实物与内部复核分层保存；可读子集不冒称完整归档。'
            '本文索引为仓库材料位置，匿名副本按另列的实际清单解释，不混用原件与转换件摘要。', 'appendix_four_studies')

        retained = []
        for index, element in enumerate(old):
            if index not in changed:
                assert element.getparent() is body and xml_hash(element) == old_hashes[index], index
                retained.append(index)
        for key, path in {'math': './/m:oMath', 'drawings': './/w:drawing', 'sections': './/w:sectPr'}.items():
            current = [xml_hash(e) for e in document.findall(path, NS)]
            previous_index = -1
            for value in old_features[key]:
                previous_index = current.index(value, previous_index + 1)
        replacements = {'word/document.xml': etree.tostring(document, xml_declaration=True, encoding='UTF-8', standalone=True)}
        parts = {n: sha(source.read(n)) for n in source.namelist()}
        with zipfile.ZipFile(OUTPUT, 'w', compression=zipfile.ZIP_DEFLATED) as out:
            for info in source.infolist():
                out.writestr(info, replacements.get(info.filename, source.read(info.filename)))
    (WORK / 'authoring-edits.json').write_text(json.dumps(edits, ensure_ascii=False, indent=2) + '\n')
    result = {'source_docx_sha256': EXPECTED, 'candidate_before_toc_sha256': sha(OUTPUT.read_bytes()),
              'original_body_child_hashes': old_hashes, 'modified_base_body_indices': sorted(changed),
              'retained_base_body_indices': retained, 'original_features': old_features,
              'original_parts': parts, 'new_features': {k: len(document.findall(p, NS)) for k,p in {
                  'math': './/m:oMath', 'drawings': './/w:drawing', 'sections': './/w:sectPr', 'tables': './/w:tbl'}.items()}}
    (WORK / 'initial-structure.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    assert sha(ORIGINAL.read_bytes()) == EXPECTED
    print(json.dumps({k: v for k, v in result.items() if k in ['candidate_before_toc_sha256', 'new_features', 'modified_base_body_indices']}))


if __name__ == '__main__':
    main()
